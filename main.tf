#############################
#   CONFIGURACIÓN GLOBAL   #
#############################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.26"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

########################
#      VARIABLES       #
########################

variable "ami_id" {
  description = "ID de la AMI para la instancia EC2 (Amazon Linux 2 en us-east-1)"
  default     = "ami-0440d3b780d96b29d"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  # t2.micro está en el Free Tier y es soportado en todas las AZ us-east-1
  default     = "t2.micro"
}

variable "server_name" {
  description = "Nombre lógico de las instancias de la aplicación"
  default     = "app-server"
}

variable "environment" {
  description = "Ambiente de la aplicación"
  default     = "test"
}

variable "ssh_ingress_cidr" {
  description = "Rango de IPs con acceso SSH (en laboratorio 0.0.0.0/0)"
  default     = "0.0.0.0/0"
}

variable "owner_email" {
  description = "Owner para etiquetar recursos"
  default     = "cldiazl@uce.edu.ec"
}

########################
#      PROVIDERS       #
########################

provider "aws" {
  region = "us-east-1"
}

########################
#      RED (VPC)       #
########################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################
#   SSH KEY PAIR PRO   #
########################

# 1) Generamos un par de llaves SSH
resource "tls_private_key" "app_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2) Registramos la llave pública en AWS como Key Pair
resource "aws_key_pair" "app_server_ssh" {
  key_name   = "${var.server_name}-ssh"
  public_key = tls_private_key.app_ssh.public_key_openssh

  tags = {
    Name        = "${var.server_name}-ssh"
    Environment = var.environment
    Owner       = var.owner_email
    Team        = "DevOps"
    Project     = "UCE"
  }
}

# 3) Guardamos la llave privada localmente para poder conectar por SSH
resource "local_file" "ssh_private_key" {
  filename = "${var.server_name}.pem"
  content  = tls_private_key.app_ssh.private_key_pem

  file_permission = "0600"
}

########################
#   SECURITY GROUPS    #
########################

# SG para el Load Balancer (recibe tráfico de Internet)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Permite HTTP desde Internet hacia el ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg"
    Environment = var.environment
    Owner       = var.owner_email
    Project     = "UCE"
  }
}

# SG para las instancias de la app
resource "aws_security_group" "app_server_sg" {
  name        = "app-server-sg"
  description = "Permite HTTP desde el ALB y SSH para administracin"
  vpc_id      = data.aws_vpc.default.id

  # HTTP SOLO desde el ALB (buena práctica)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH desde el rango definido (laboratorio: 0.0.0.0/0)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "app-server-sg"
    Environment = var.environment
    Owner       = var.owner_email
    Project     = "UCE"
  }
}

########################
#   LAUNCH TEMPLATE    #
########################

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.app_server_ssh.key_name

  vpc_security_group_ids = [aws_security_group.app_server_sg.id]

  # Script de arranque: Docker + docker-compose + tu app
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Actualizar paquetes
    yum update -y

    # Instalar Docker y git
    yum install -y docker git

    systemctl enable docker
    systemctl start docker

    # Instalar docker-compose (binario clásico)
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true

    # Preparar carpeta de la app
    mkdir -p /srv/app
    cd /srv/app

    # Clonar tu repo con backend + DB
    git clone https://github.com/ChrisD14/CorrecionDistri.git .

    # Levantar los contenedores
    docker-compose pull || true
    docker-compose up -d
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = var.server_name
      Environment = var.environment
      Owner       = var.owner_email
      Team        = "DevOps"
      Project     = "UCE"
    }
  }
}

########################
#   LOAD BALANCER      #
########################

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "app-alb"
    Environment = var.environment
    Owner       = var.owner_email
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  # Healthcheck apuntando al endpoint /health del backend
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 3
  }

  tags = {
    Name        = "app-tg"
    Environment = var.environment
    Owner       = var.owner_email
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

########################
#   AUTO SCALING GRP   #
########################

resource "aws_autoscaling_group" "app_asg" {
  name                      = "app-asg"
  min_size                  = 4
  max_size                  = 6
  desired_capacity          = 4
  health_check_type         = "EC2"
  health_check_grace_period = 120

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.server_name
    propagate_at_launch = true
  }
}

########################
#        OUTPUTS       #
########################

# DNS público del Load Balancer (para probar la app)
output "alb_dns_name" {
  description = "DNS público del Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

# Capacidad deseada del ASG
output "asg_desired_capacity" {
  description = "Capacidad deseada del Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.desired_capacity
}

# ARN del Load Balancer
output "alb_arn" {
  description = "ARN del Load Balancer"
  value       = aws_lb.app_alb.arn
}

# ARN del Target Group
output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.app_tg.arn
}

# ARN del Listener del ALB
output "listener_arn" {
  description = "ARN del Listener del ALB"
  value       = aws_lb_listener.app_listener.arn
}

# ID del Security Group de las instancias
output "instance_sg_id" {
  description = "Security Group ID usado por las instancias EC2"
  value       = aws_security_group.app_server_sg.id
}

# ID del Security Group del ALB
output "alb_sg_id" {
  description = "Security Group ID usado por el ALB"
  value       = aws_security_group.alb_sg.id
}

# ID del Auto Scaling Group
output "asg_id" {
  description = "ID del Auto Scaling Group"
  value       = aws_autoscaling_group.app_asg.id
}

# ARN del Launch Template
output "launch_template_arn" {
  description = "ARN del Launch Template usado por el ASG"
  value       = aws_launch_template.app_lt.arn
}

# Subnets utilizadas
output "subnets_ids" {
  description = "Subnets utilizadas por la infraestructura"
  value       = data.aws_subnets.default.ids
}

# Ruta al archivo de la llave privada generada
output "ssh_private_key_file" {
  description = "Ruta local al archivo .pem para conectarse por SSH a las instancias"
  value       = local_file.ssh_private_key.filename
}
