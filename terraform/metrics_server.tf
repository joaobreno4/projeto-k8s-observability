# 1. Conta de Serviço do Sistema (ServiceAccount)
resource "kubernetes_service_account" "metrics_server" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "metrics-server"
    }
  }
}

# 2. Permissões Globais do Cluster Corrigidas (ClusterRole)
resource "kubernetes_cluster_role" "metrics_server" {
  metadata {
    name = "system:metrics-server"
    labels = {
      "k8s-app"                     = "metrics-server"
      "kubernetes.io/bootstrapping" = "rbac-defaults"
    }
  }

  # Coleta de métricas de hardware nos nós e pods
  rule {
    api_groups = [""]
    resources  = ["nodes/metrics", "nodes/stats", "nodes/proxy", "pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  # Correção de RBAC: Autorização via Webhook (SubjectAccessReview)
  rule {
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
    verbs      = ["create"]
  }

  # Correção de RBAC: Autenticação via Webhook (TokenReview)
  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
}

# 3. Permissões de Agregação de Visualização de Métricas
resource "kubernetes_cluster_role" "system_aggregated_metrics_reader" {
  metadata {
    name = "system:aggregated-metrics-reader"
    labels = {
      "rbac.authorization.k8s.io/aggregate-to-view"  = "true"
      "rbac.authorization.k8s.io/aggregate-to-edit"  = "true"
      "rbac.authorization.k8s.io/aggregate-to-admin" = "true"
    }
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

# 4. Vinculação das Permissões Globais (ClusterRoleBinding)
resource "kubernetes_cluster_role_binding" "metrics_server" {
  metadata {
    name = "system:metrics-server"
    labels = {
      "k8s-app" = "metrics-server"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.metrics_server.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.metrics_server.metadata[0].name
    namespace = "kube-system"
  }
}

# 5. Vinculação de Leitura de Autenticação de Extensão (RoleBinding)
resource "kubernetes_role_binding" "metrics_server_auth_reader" {
  metadata {
    name      = "metrics-server-auth-reader"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "metrics-server"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.metrics_server.metadata[0].name
    namespace = "kube-system"
  }
}

# 6. Service Interno para Roteamento de Métricas (Porta Alinhada)
resource "kubernetes_service" "metrics_server" {
  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "metrics-server"
    }
  }

  spec {
    selector = {
      "k8s-app" = "metrics-server"
    }

    port {
      name        = "https"
      port        = 443
      target_port = 4443 # Alinhado com a escuta interna livre
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# 7. Deployment do Pod do Metrics Server (Arquitetura ideal para Kind no WSL2)
resource "kubernetes_deployment_v1" "metrics_server" {
  depends_on = [kind_cluster.lab_puro]

  metadata {
    name      = "metrics-server"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "metrics-server"
    }
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "metrics-server"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app" = "metrics-server"
        }
      }

      spec {
        priority_class_name  = "system-cluster-critical"
        service_account_name = kubernetes_service_account.metrics_server.metadata[0].name
        
        # Ativo para vencer as barreiras de NAT do Docker-in-Docker no WSL2
        host_network         = true 

        container {
          name              = "metrics-server"
          image             = "registry.k8s.io/metrics-server/metrics-server:v0.8.1"
          image_pull_policy = "IfNotPresent"

          # Argumentos amarrados para rodar na porta 4443 sem conflito de Kubelet
          args = [
            "--cert-dir=/tmp",
            "--secure-port=4443",
            "--kubelet-preferred-address-types=InternalIP",
            "--kubelet-use-node-status-port",
            "--metric-resolution=15s",
            "--kubelet-insecure-tls" # Ignora validações estritas de certificados locais
          ]

          port {
            name           = "https"
            container_port = 4443
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "200Mi"
            }
          }

          volume_mount {
            name       = "tmp-dir"
            mount_path = "/tmp"
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 1000
            seccomp_profile {
              type = "RuntimeDefault"
            }
          }
        }

        volume {
          name = "tmp-dir"
          empty_dir {}
        }
      }
    }
  }
}

# 8. Registro do APIService Corrigido com Bypass de TLS do HostNetwork
resource "kubernetes_manifest" "metrics_server_apiservice" {
  depends_on = [kubernetes_service.metrics_server]

  manifest = {
    apiVersion = "apiregistration.k8s.io/v1"
    kind       = "APIService"
    metadata = {
      name = "v1beta1.metrics.k8s.io"
    }
    spec = {
      group                 = "metrics.k8s.io"
      groupPriorityMinimum  = 100
      versionPriority       = 100
      version               = "v1beta1"
      insecureSkipTLSVerify = true # Permite que o plano de controle leia os dados do nó hospedeiro
      
      service = {
        name      = "metrics-server"
        namespace = "kube-system"
        port      = 443
      }
    }
  }
}
