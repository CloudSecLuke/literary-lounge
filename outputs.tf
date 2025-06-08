output "droplet_ip" {
  value = digitalocean_droplet.wordpress.ipv4_address
}

output "ssh_command" {
  value = "ssh root@${digitalocean_droplet.wordpress.ipv4_address}"
}

output "hostname" {
  value = digitalocean_droplet.wordpress.name
}

output "wordpress_url" {
  value = "https://${var.domain_name}"
}
