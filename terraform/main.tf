
##############################################
# This module will deploy:
#  VPC
#  2x subnets in 2 different available AZ
#  Internet gateway with routing table attached
#  Security group
#  Autoscaling group using launch configuration
#  ELB for ASG
#
# Outputs: ELB FQDN
# Deployed web service will be available at http://ELB_FQDN:5000

##############################################
# Local variables
##############################################
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

##############################################
# Network resources
##############################################
resource "aws_vpc" "takehomel3l4" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "takehomel3l4-primary" {
  vpc_id                  = aws_vpc.takehomel3l4.id
  cidr_block              = var.subnet-primary
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.takehomel3l4.names[0]
}

resource "aws_subnet" "takehomel3l4-secondary" {
  vpc_id                  = aws_vpc.takehomel3l4.id
  cidr_block              = var.subnet-secondary
  map_public_ip_on_launch = "true"
  availability_zone       = data.aws_availability_zones.takehomel3l4.names[1]
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

##############################################
# Compute resources 
##############################################
resource "aws_key_pair" "takehomel3l4" {
  key_name   = "takehomel3l4-Public-Key"
  public_key = file(var.instance-public-key)
}

resource "aws_launch_configuration" "takehomel3l4" {
  name_prefix                 = "takehomel3l4-"
  image_id                    = var.instance-ami
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.takehomel3l4.key_name
  security_groups             = concat([aws_security_group.takehomel3l4.id], var.additional_security_group_ids)
  associate_public_ip_address = true
  user_data                   = local.user_data
  root_block_device {
    delete_on_termination = true
    volume_size           = 20
    volume_type           = "gp2"
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_security_group.takehomel3l4]
}

resource "aws_autoscaling_group" "takehomel3l4" {
  name                 = "${aws_launch_configuration.takehomel3l4.name}-asg"
  min_size             = 1
  desired_capacity     = 2
  max_size             = 4
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.takehomel3l4.id]
  launch_configuration = aws_launch_configuration.takehomel3l4.name
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  vpc_zone_identifier = [
    aws_subnet.takehomel3l4-primary.id,
    aws_subnet.takehomel3l4-secondary.id
  ]
  # Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "Take Home L3/L4 ASG"
    propagate_at_launch = true
  }
}

resource "aws_elb" "takehomel3l4" {
  name            = "takehomel3l4-elb"
  security_groups = concat([aws_security_group.takehomel3l4.id], var.additional_security_group_ids)
  subnets = [
    aws_subnet.takehomel3l4-primary.id,
    aws_subnet.takehomel3l4-secondary.id
  ]
  cross_zone_load_balancing = true
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    target              = "HTTP:5000/"
  }
  listener {
    lb_port           = 5000
    lb_protocol       = "http"
    instance_port     = 5000
    instance_protocol = "http"
  }
}

##############################################
# Outputs
##############################################
output "elb_dns_name" {
  value = aws_elb.takehomel3l4.dns_name
}

output "elb_instances" {
  value = aws_elb.takehomel3l4.instances
}

##############################################
# Data providers
##############################################
data "aws_availability_zones" "takehomel3l4" {
  state = "available"
}
