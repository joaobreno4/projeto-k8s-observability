resource "kubernetes_deployment_v1" "api_deployment" {
  metadata {
    name      = "api-deployment"
    namespace = "default"
    labels = {
      app = "api-autoscale"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "api-autoscale"
      }
    }

    template {
      metadata {
        labels = {
          app = "api-autoscale"
        }
      }

      spec {
        container {
          name              = "api-container"
          image             = "api-autoscale:v1"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 8000
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "api_service" {
  metadata {
    name      = "api-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "api-autoscale"
    }

    port {
      port        = 8000
      target_port = 8000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "api_hpa" {
  depends_on = [kubernetes_deployment_v1.api_deployment]

  metadata {
    name      = "api-hpa"
    namespace = "default"
  }

  spec {
    max_replicas = 5
    min_replicas = 1

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "api-deployment"
    }

    target_cpu_utilization_percentage = 50
  }
}
