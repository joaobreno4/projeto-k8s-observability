terraform {
  required_version = ">= 1.0.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  host                   = kind_cluster.lab_puro.endpoint
  client_certificate     = kind_cluster.lab_puro.client_certificate
  client_key             = kind_cluster.lab_puro.client_key
  cluster_ca_certificate = kind_cluster.lab_puro.cluster_ca_certificate
}
