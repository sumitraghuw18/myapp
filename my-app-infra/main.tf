resource "aws_ecs_cluster" "main" {
  name = "ecs-todo-cluster"
}

resource "aws_instance" "ecs_instance" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = "t3.micro" # ✅ Free tier
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ecs_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  associate_public_ip_address = true
  user_data                   = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF
  tags                        = { Name = "ecs-todo-instance" }
}

# Latest Amazon ECS-Optimized AMI
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ------------------------------
# Cloud Watch Log Group
# ------------------------------
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/todo-app"
  retention_in_days = 1 # keep logs for a week (can adjust)
}

# ------------------------------
# ECS Task Definition
# ------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = "todo-app-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([
    {
      name      = "todo-app"
      image     = var.docker_image # e.g., "your-dockerhub-username/todo-app:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/todo-app"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# ------------------------------
# ECS Service
# ------------------------------
resource "aws_ecs_service" "app" {
  name            = "todo-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "EC2"
}
