output "endpoint" {
  depends_on = [digitalocean_kubernetes_cluster.graylog]
  value      = digitalocean_kubernetes_cluster.graylog.endpoint
}

output "id" {
  depends_on = [digitalocean_kubernetes_cluster.graylog]
  value      = digitalocean_kubernetes_cluster.graylog.id
}

output "name" {
  depends_on = [digitalocean_kubernetes_cluster.graylog]
  value      = digitalocean_kubernetes_cluster.graylog.name
}
