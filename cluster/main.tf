provider "digitalocean" {}

data "digitalocean_kubernetes_versions" "available" {
  version_prefix = "1.21."
}

resource "digitalocean_kubernetes_cluster" "graylog" {
  name    = "graylog"
  region  = var.region
  version = data.digitalocean_kubernetes_versions.available.latest_version

  node_pool {
    name       = "graylog-node"
    size       = var.node_type
    node_count = 3
  }
}

# new tokens sometimes take a few seconds to start working
resource "null_resource" "delay_token" {
  provisioner "local-exec" {
    command = "sleep 30"
  }

  triggers = {
    token = digitalocean_kubernetes_cluster.graylog.kube_config[0].token
  }
}

resource "local_file" "kubeconfig" {
  depends_on = [digitalocean_kubernetes_cluster.graylog, null_resource.delay_token]

  filename = pathexpand("~/.kube/config.do.graylog")
  content = templatefile("${path.module}/kubeconfig.tpl", {
    ca       = digitalocean_kubernetes_cluster.graylog.kube_config[0].cluster_ca_certificate
    endpoint = digitalocean_kubernetes_cluster.graylog.endpoint
    token    = digitalocean_kubernetes_cluster.graylog.kube_config[0].token
  })
}
