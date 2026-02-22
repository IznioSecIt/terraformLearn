provider "aws" {
  region = "eu-west-3"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [ data.aws_vpc.default.id ]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  description = "Allow access to webserver"

  tags = {
    Name = "allow_webserver_access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.server_port
  ip_protocol       = "tcp"
  to_port           = var.server_port
}

resource "aws_instance" "example" {
  ami = "ami-0c5c1b3399d21cdc6"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ aws_security_group.instance.id ]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup python3 -m http.server ${var.server_port} &
              EOF
  
  user_data_replace_on_change = true

  tags = {
    Name =  "terraform-example" 
  }
}

resource "aws_launch_template" "example" {

  image_id = "ami-0c5c1b3399d21cdc6"
  instance_type = "t3.micro"
  vpc_security_group_ids = [ aws_security_group.instance.id ]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup python3 -m http.server ${var.server_port} &
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "example" {

  vpc_zone_identifier = data.aws_subnets.default.ids

  min_size = 2
  max_size = 5

  launch_template {
    id = aws_launch_template.example.id  
  }

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}