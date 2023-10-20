output "Region" {
  value = var.region
}

output "threatcode_public_ips" {
  description = "Threat Code Public IP Address(es)"
  value = google_compute_instance.sensor.network_interface[0].access_config[0].nat_ip
}

output "ubuntu_public_ips" {
  description = "Ubuntu Instance IP Address(es)"
  value = google_compute_instance.host.network_interface[0].access_config[0].nat_ip
}
