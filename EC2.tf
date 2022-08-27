data "aws_vpc" "vpc_available" {
  filter {
    name   = "tag:Name"
    values = ["puneet_vpc"]
  }
}
variable "ami_id" {
  type    = string
  default = "ami-0c4f7023847b90238"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "associate_public_ip" {
  type    = bool
  default = true
}

variable "az" {
  type    = string
  default = "us-east-1a"
}

variable "disable_api_termination" {
  type    = bool
  default = false
}

variable "instance_profile" {
  type    = string
  default = "ec2"
}

variable "volume_size" {
  type    = number
  default = 10
}

variable "application" {
  type    = string
  default = "puneet"
}

variable "organization" {
  type    = string
  default = "puneetrock"
}


data "aws_iam_instance_profile" "instance_profile" {
  name = "EC2CodedeployRole"
}

data "aws_availability_zone" "az" {
  name                   = "us-east-1a"
  all_availability_zones = false
  state                  = "available"
}

data "aws_key_pair" "key" {
  key_name = "ubuntu-server"
}

data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.vpc_available.id
  availability_zone = "us-east-1a"
  filter {
    name   = "tag:Name"
    values = ["puneet_public_subnet_az_1a"]
  }
}



resource "aws_instance" "instance" {
  ami                         = var.ami_id # us-east-1
  instance_type               = var.instance_type
  associate_public_ip_address = var.associate_public_ip
  availability_zone           = data.aws_availability_zone.az.id
  disable_api_termination     = var.disable_api_termination
  iam_instance_profile        = data.aws_iam_instance_profile.instance_profile.role_name
  key_name                    = data.aws_key_pair.key.key_name
  security_groups             = null
  vpc_security_group_ids      = data.aws_security_groups.sg.ids
  subnet_id                   = data.aws_subnet.selected.id
  user_data                   = file("${path.module}/user-data.sh")
  hibernation = false
  credit_specification {
    cpu_credits = "standard"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = var.volume_size
    volume_type           = "gp2"
    tags = {
      Name         = "production"
      application  = var.application
      organization = var.organization
    }
  }
  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
  tags = {
    Name         = "production"
    application  = var.application
    organization = var.organization
  }
}

resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = "us-east-1a"
  size              = 10
  snapshot_id       = null
  type              = "gp2"
  tags = {
    Name         = "ebs_volume"
    application  = var.application
    organization = var.organization
  }
}

resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.instance.id
}