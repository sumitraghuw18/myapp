output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "public_instance_ip" {
  value = aws_instance.ecs_instance.public_ip
}
