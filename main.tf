provider "aws" {
  region = "eu-west-2" # Change to your desired region
}

resource "aws_security_group" "instance_sg" {
  name_prefix = "instance_sg_"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example_instance" {
  ami           = "ami-0f3d9639a5674d559" # Change to your desired AMI ID
  instance_type = "t2.micro" # Change to your desired instance type
  key_name      = "sre" # Change to your key pair name
  security_groups = [aws_security_group.instance_sg.name]
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb_sg_"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example_lb" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0e0bc4090156df9e4", "subnet-0399a69384f819087", "subnet-0c4644dc37cf09b12"] # Change to your subnet IDs

  enable_deletion_protection = false

  enable_http2 = true
}

resource "aws_lb_target_group" "example_target_group" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-011537bcda1c945ca" # Change to your VPC ID
}

resource "aws_lb_listener" "example_listener" {
  load_balancer_arn = aws_lb.example_lb.arn
  port              = 80
  default_action {
    target_group_arn = aws_lb_target_group.example_target_group.arn
    type             = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hello, world!"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "example_listener_rule" {
  listener_arn = aws_lb_listener.example_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_target_group.arn
  }

  condition {
    path_pattern {
    values = ["/"]
  }
}
}
