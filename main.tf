provider "aws" {
  region = "eu-west-3"
}

resource "aws_instance" "example" {
  ami = "ami-0c5c1b3399d21cdc6"
  instance_type = "t2.nano"

  tags = {
    Name =  "terraform-example" 
  }
}