output "Region" {
  value = var.region
}

output "threatcode_public_ips" {
  description = "Threat Code Public IP Address(es)"
  value = aws_instance.threatcode[*].public_ip
}

output "windows_public_ips" {
  description = "Windows Instance IP Address(es)"
  value = aws_instance.windows_instance[*].public_ip
}

output "ubuntu_public_ips" {
  description = "Ubuntu Instance IP Address(es)"
  value = aws_instance.ubuntu_instance[*].public_ip
}


