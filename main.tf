variable "ec2-key" {
  type = string
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
  tags = {
  "Project" : "firstproject"
  "Terraform" : "True"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
  tags = {
  "Project" : "firstproject"
  "Terraform" : "True"
  }
}

resource "aws_security_group" "SG-firstproject" {
  name        = "SG-firstproject"
  description = "Security group to allow ssh an http access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
  "Project" : "firstproject"
  "Terraform" : "True"
  }
}

resource "aws_elb" "web-elb" {
  name            = "web-elb"
  subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.SG-firstproject.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  tags = {
    "Project" : "firstproject"
    "Terraform" : "True"
    "Name" : "web-elb"
  }
}

resource "aws_launch_template" "autoscaling" {
  name_prefix   = "autoscaling"
  image_id      = "ami-0c293f3f676ec4f90"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "autoscaling" {
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1

  launch_template {
    id      = aws_launch_template.autoscaling.id
    version = "$Latest"
  }
  tag {
    key                = "Terraform"
    value              = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.autoscaling.id
  elb                    = aws_elb.web-elb.id
}
