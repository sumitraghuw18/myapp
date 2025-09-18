variable "aws_region" {
  default = "us-east-1"
}

variable "docker_image" {
  description = "Docker image for the app"
  type        = string
  default     = "public.ecr.aws/x4r2d7o8/todo-app:latest"
}
