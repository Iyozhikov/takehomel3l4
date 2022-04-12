

## LOCALS
locals {
  server_code    = file("${path.module}/user-data/server.py")
  server_starter = file("${path.module}/user-data/server.sh")
  server_unit    = file("${path.module}/user-data/server.service")
  user_data = templatefile("${path.module}/user-data/user-data.sh",
    {
      server_code    = local.server_code
      server_starter = local.server_starter
      server_unit    = local.server_unit
    }
  )
}

## NETWORKING
resource "aws_vpc" "takehomel3l4" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "takehomel3l4" {
  vpc_id                  = aws_vpc.takehomel3l4.id
  cidr_block              = var.subnet
  map_public_ip_on_launch = "true"
}

resource "aws_internet_gateway" "takehomel3l4" {
  vpc_id = aws_vpc.takehomel3l4.id
}

resource "aws_default_route_table" "takehomel3l4" {
  default_route_table_id = aws_vpc.takehomel3l4.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.takehomel3l4.id
  }
}

resource "aws_security_group" "takehomel3l4" {
  name        = "APP_Access"
  description = "Application traffic in/out"
  vpc_id      = aws_vpc.takehomel3l4.id
  lifecycle {
    create_before_destroy = true
  }
}

# Creating security group rules 
resource "aws_security_group_rule" "takehomel3l4" {
  for_each          = var.security_group_rules
  type              = each.value.type
  from_port         = each.value.from
  to_port           = each.value.to
  protocol          = each.value.proto
  cidr_blocks       = each.value.cidrs
  description       = each.value.desc
  security_group_id = aws_security_group.takehomel3l4.id
}

## INSTANCE
resource "aws_key_pair" "takehomel3l4" {
  key_name   = "takehomel3l4-Public-Key"
  public_key = file(var.instance-public-key)
}

resource "aws_instance" "takehomel3l4" {
  ami                         = var.instance-ami
  instance_type               = var.instance-type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.takehomel3l4.id
  vpc_security_group_ids      = concat([aws_security_group.takehomel3l4.id], var.additional_security_group_ids)
  key_name                    = aws_key_pair.takehomel3l4.key_name
  user_data                   = local.user_data
  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }
  depends_on = [aws_security_group.takehomel3l4]
}

output "ec2_public_ip" {
  value       = aws_instance.takehomel3l4.public_ip
  sensitive   = false
  description = "Instance public IP"
}
