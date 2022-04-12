

##############################################
# Module variables
##############################################

variable "cidr_block" {
  default     = "10.100.0.0/16"
  description = "Default VPC cidr range"
}

variable "subnet-primary" {
  default     = "10.100.0.0/24"
  description = "Default primary subnet range"
}
variable "subnet-secondary" {
  default     = "10.100.1.0/24"
  description = "Default secondary subnet range"
}

variable "security_group_rules" {
  type = map(object(
    {
      from  = number
      to    = number
      proto = string
      cidrs = list(string)
      desc  = string
      type  = string
    }
  ))
  default = {
    ssh    = { from = 22, to = 22, proto = "tcp", cidrs = ["0.0.0.0/0"], desc = "Inbound SSH", type = "ingress" }
    app    = { from = 5000, to = 5000, proto = "tcp", cidrs = ["0.0.0.0/0"], desc = "Inbound APP", type = "ingress" }
    outall = { from = 0, to = 0, proto = "-1", cidrs = ["0.0.0.0/0"], desc = "Outbound all", type = "egress" }
  }
  description = "Default security group rules"
}

variable "additional_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Additional security group ids"
}

variable "instance-ami" {
  default     = "ami-08aca7d5089745fbb"
  description = "Default machine image"
}

variable "instance-type" {
  default     = "t2.micro" #1CPU, 1Gb RAM
  description = "Defalt instance type"
}
variable "instance-public-key" {
  default     = "~/.ssh/keys/aws/id_rsa.pub"
  description = "Default ssh public key"
}