output "id" {
  description = "The ID of the instance"
  value = ["${module.app_instance.*.id}"]
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value = ["${module.app_instance.*.private_ip}"]
  
}