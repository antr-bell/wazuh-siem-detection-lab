output "wazuh_dashboard_url" {
  value = "https://${aws_instance.sec_lab.public_ip}"
}

output "ssh_command" {
  value = "ssh -i ./wazuh-lab-key.pem ubuntu@${aws_instance.sec_lab.public_ip}"
}