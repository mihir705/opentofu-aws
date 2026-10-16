output "instance_id" {
  description = "EC2 instance ID."
  value       = local.instance.id
}

output "instance_arn" {
  description = "EC2 instance ARN."
  value       = local.instance.arn
}

output "instance_state" {
  description = "EC2 instance state."
  value       = local.instance.instance_state
}

output "private_ip" {
  description = "Primary private IPv4 address."
  value       = local.instance.private_ip
}

output "public_ip" {
  description = "Public IPv4 address assigned to the instance or Elastic IP."
  value       = var.create_eip ? aws_eip.this[0].public_ip : local.instance.public_ip
}

output "private_dns" {
  description = "Private DNS name."
  value       = local.instance.private_dns
}

output "public_dns" {
  description = "Public DNS name."
  value       = local.instance.public_dns
}

output "availability_zone" {
  description = "Availability zone of the instance."
  value       = local.instance.availability_zone
}

output "ami_id" {
  description = "AMI ID used by the instance."
  value       = local.instance.ami
}

output "primary_network_interface_id" {
  description = "Primary network interface ID."
  value       = local.instance.primary_network_interface_id
}

output "eip_allocation_id" {
  description = "Elastic IP allocation ID when create_eip is true."
  value       = try(aws_eip.this[0].id, null)
}

output "eip_public_ip" {
  description = "Elastic IP public address when create_eip is true."
  value       = try(aws_eip.this[0].public_ip, null)
}

output "root_block_device_volume_id" {
  description = "Root EBS volume ID."
  value       = try(local.instance.root_block_device[0].volume_id, null)
}

output "ebs_block_device_volume_ids" {
  description = "Additional EBS volume IDs keyed by device name."
  value       = { for device in local.instance.ebs_block_device : device.device_name => device.volume_id }
}
