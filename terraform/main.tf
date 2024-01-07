provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "kubeadm-proj" {
    key_name = "kubeadm-proj"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjRO4YQmzvra2fvN4r/AKBTYSfNO3WaHJDT0UZxXmv6xemhLu92wGk4mghyBji58shxmKcyEjL2WWvqpG3XTmE7ju2ZwBUdRNFNCqQ1ku1XRblFm4fMv0kex8dHRKzs5CpCcacLRINmdLMNybe+OaLVPuhsAWjLzHK4qktg47jyiyXoxwxQGQqqBjTW0ifIp8ik+VPpRRqxT7rJF9euYUnNcaEv2525aQ6OHjGTdCTHwQf3GVaXcB0Vd89KZEGaXvCFfA+X/OP7JF8Wz7cZoKVHsxHNuF0VDv1+7cA7RN7c+pLwqCiI6l21KaCRbRxpJrBSwfeBqAR7/2tGS29RgnR7SV2engGcT6BWX+Aiz192Hakt59l/tu724euzAC2vNy8gN7FLa7Tx1UE6QzIA9wFs68n6mSuI5bo6X1WbOkFBOpqrM/GZCbYRGqPHE4jkI8hXbIUBtVvPJSDa69+07UOESLExtCY1oCqXk4JuKcBsIIYKoeUShifDCg0hiWThDc= devopslab@MBP-2"
  
}

# VPC
resource "aws_vpc" "kubeadm_proj" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "kubeadm-proj"
  }
}

# Subnet
resource "aws_subnet" "kubeadm_proj_subnet" {
  vpc_id                  = aws_vpc.kubeadm_proj.id
  cidr_block              = "10.0.1.0/24"

  tags = {
    Name = "kubeadm-proj"
  }
}


resource "aws_eip" "nat" {
  domain   = "vpc"

}

resource "aws_nat_gateway" "natgw" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.kubeadm_proj_subnet.id
}

# Internet Gateway
resource "aws_internet_gateway" "kubeadm_proj_igw" {
  vpc_id = aws_vpc.kubeadm_proj.id

  tags = {
    Name = "kubeadm-proj"
  }
}

# Route Table
resource "aws_route_table" "kubeadm_proj_route_table" {
  vpc_id = aws_vpc.kubeadm_proj.id

  tags = {
    Name = "kubeadm-proj"
  }
}

resource "aws_route_table_association" "pub-rtassoc" {
  subnet_id      = aws_subnet.kubeadm_proj_subnet.id
  route_table_id = aws_route_table.kubeadm_proj_route_table.id
}

resource "aws_route" "kubeadm_proj_route" {
  route_table_id         = aws_route_table.kubeadm_proj_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kubeadm_proj_igw.id
}

# resource "aws_security_group" "kubeadm_proj_sg" {
#   name        = "kubeadm-proj"
#   description = "kubeadm-proj security group"
#   vpc_id      = aws_vpc.kubeadm_proj.id
# }

# resource "aws_security_group_rule" "kubeadm_proj_sg_rule" {
#   security_group_id = aws_security_group.kubeadm_proj_sg.id
#   type              = "ingress"
#   protocol          = "tcp"
#   cidr_blocks       = ["10.0.0.0/16", "10.200.0.0/16", "0.0.0.0/0"]
#   from_port         = 0
#   to_port           = 65535
# }

resource "aws_security_group" "kubeadm_proj_sg" {
  name        = "kubeadm-proj"
  description = "kubeadm-proj security group"
  vpc_id      = aws_vpc.kubeadm_proj.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 2380
    to_port   = 2380
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 30000
    to_port   = 32767
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Add more ingress rules as needed for your specific setup

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load Balancer
resource "aws_lb" "kubeadm_proj_lb" {
  name               = "kubeadm-proj"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.kubeadm_proj_subnet.id]
}

resource "aws_lb_target_group" "kubeadm_proj_tg" {
  name     = "kubeadm-proj"
  protocol = "TCP"
  port     = 6443
  vpc_id   = aws_vpc.kubeadm_proj.id
}

resource "aws_lb_listener" "kubeadm_proj_listener" {
  load_balancer_arn = aws_lb.kubeadm_proj_lb.arn
  protocol          = "TCP"
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kubeadm_proj_tg.arn
  }
}

# Compute Instances
resource "aws_instance" "kubeadm_proj_controller" {
  count         = 3
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.kubeadm_proj_subnet.id
  key_name      = aws_key_pair.kubeadm-proj.key_name
  private_ip    = "10.0.1.1${count.index}"
  vpc_security_group_ids = [ aws_security_group.kubeadm_proj_sg.id ]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    name=controller-${count.index}
    EOF

   ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
  }

  tags = {
    Name = "controller-${count.index}"
  }
}

resource "aws_instance" "kubeadm_proj_worker" {
  count         = 3
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.kubeadm_proj_subnet.id
  key_name      = aws_key_pair.kubeadm-proj.key_name
  vpc_security_group_ids = [ aws_security_group.kubeadm_proj_sg.id ]
  private_ip    = "10.0.1.2${count.index}"
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    name=worker-${count.index}|pod-cidr=10.200.${count.index}.0/24
    EOF

   ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 50
  }

  tags = {
    Name = "worker-${count.index}"
  }
}
