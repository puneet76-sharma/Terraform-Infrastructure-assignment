
################################################################################
# VPC
################################################################################

resource "aws_vpc" "myVPC" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "puneet_vpc"
  }
}

###############################################################################
# Internet Gateway
###############################################################################

resource "aws_internet_gateway" "myIGW" {

  vpc_id = aws_vpc.myVPC.id
  tags = {
    "Name" = "puneet_igw"
  }
}

################################################################################
# Availability Zones list out
################################################################################

data "aws_availability_zones" "available_1" {
  state = "available"
}

################################################################################
# Public subnet
################################################################################

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = data.aws_availability_zones.available_1.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "puneet_public_subnet_az_1a"
  }
}


resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "192.168.2.0/24"
  availability_zone       = data.aws_availability_zones.available_1.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "puneet_public_subnet_az_1b"
  }
}

################################################################################
# Publiс routes
################################################################################

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    Name = "puneet_public_route_table"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myIGW.id
}


################################################################################
# Route table association with subnets
################################################################################

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "sg" {
  name        = "puneet_security_group"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  ingress = [
    {
      description      = "All traffic"
      from_port        = 0    # All ports
      to_port          = 0    # All Ports
      protocol         = "-1" # All traffic
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      description      = "Outbound rule"
      prefix_list_ids  = null
      security_groups  = null
      self             = null
    }
  ]

  tags = {
    Name = "puneet_security_group"
  }
}