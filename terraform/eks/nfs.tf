resource "aws_key_pair" "demo_ssh" {
  key_name   = "martin_gegenleitner"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDhTwcLPwfFp+oS/sqWpgmF3s7MTBUBINhbcqnZAg6IRS2f79C5CpUbd6Xywm4FH+Mk2IY5nEB9KP+6vHuX+R9Jyw201QA/5YLaDprs8SRCMcvDzYNqA4f6T0D4aYDwFrhQEOuK2rgKDCShVthcZr8Mgdt5wZztTzGzQ/DgSeobjThXBwfbW/AE7CovbIh0Kzp/qH/H6I4M6WYKmuE7Xm7vfEy6aYnhKfKgKOqFNR6Yfudlb6kVjcctD6KAdyTVFplwV5XG0j3vpYrX+hrRes/mOwImw0KckO6gVwf8KixL+6O8VO/jVTy2EYE0LVr3+DY5nYcfr1PAtgSM3LNmStpskHnhgh29rl+jWqL5JMnd618ScjZ0T5EWngBugMSAL6u0EIjIxcO07k3sosW8T06oxkYWNzHNMTp5rn4hSPlGcelL03b9KsnnFGKywqGPWZeYUtefj7QTY7XyxO/+KSVh6+L305O9RVYJ/XGCId3f9JCbLepteE6+o34fcaCXahQONyQUAlmbCBSbwkAE28gr5L1XkD+WtNPz7n1NqWMuzjNT8Y+ZbFg8540f12EgiOfhBB69xMvcZ29r9eB2b/Ss8Rfg+x4uFfhL+B+w54oRqtMl7bricZvxhWmMDPaGtziAjKHpKM8aHwntdBANtUtPRAKA4OdMMPLAXHUj3LaJsw== martin.gegenleitner@thalesgroup.com"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "nfs_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.demo_ssh.key_name

  tags = {
    Name = "NFS-Server"
  }

  network_interface {
    network_interface_id = aws_network_interface.nfs_server_nic_pub.id
    device_index         = 0
  }

  #  network_interface {
  #    network_interface_id = aws_network_interface.nfs_server_nic_priv.id
  #    device_index         = 1
  #  }
}

resource "aws_network_interface" "nfs_server_nic_pub" {
  subnet_id       = element(module.vpc.public_subnets, 0)
  private_ips     = ["10.0.4.119"]
  security_groups = [aws_security_group.nfs_server_ports.id]

  tags = {
    Name = "NFS Server primary network interface"
  }
}

#resource "aws_network_interface" "nfs_server_nic_priv" {
#  subnet_id       = element(module.vpc.private_subnets, 0)
#  security_groups = [aws_security_group.nfs_server_ports.id]
#
#  tags = {
#    Name = "NFS Server secondary network interface"
#  }
#}

resource "aws_eip" "ip" {
  vpc               = true
  network_interface = aws_network_interface.nfs_server_nic_pub.id
}

resource "aws_security_group" "nfs_server_ports" {
  name_prefix = "nfs_server_ruleset"
  description = "Allow only ssh to pass to the NFS Server from the internet and allow NFS from all subnets of our VPC."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow incoming SSH traffic"
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "Allow incoming NFS traffic from VPC"
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description      = "Allow all outgoing traffic (provisioning)"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}