###############################################################
## Application Load Balancer
###############################################################
variable "region_name" {
  type    = string
  default = "us-east-1"
}
variable "alb_count" {
  description = "Count of ALB"
  type        = number
  default     = 2
}
variable "application_load_balancer_name" {
  description = "Name of the APplication Load Balancer"
  type        = string
  default     = "my-ALB"
}
variable "internal_or_internet_facing" {
  description = "Whether ALB should be internal or internet-facing-- True means internal & False means internet-facing"
  type        = bool
  default     = true
}
variable "deletion_protection" {
  description = "Whether deletion protection is required"
  type        = bool
  default     = false
}
variable "bucket_name_for_logs" {
  description = "Enter the bucket name to store the logs"
  type        = string
  default     = ""
}
variable "prefix_of_logs" {
  description = "Mention the prefix name for logs"
  type        = string
  default     = ""
}
variable "access_logs_enable" {
  description = "Whether access logs is required"
  type        = bool
  default     = false
}

variable "alb_environment_tag" {
  description = "mention the environment name"
  type        = string
  default     = "test"
}

variable "loadBalancer_type" {
  description = "Mention the type of load balancer you need- 'application', 'network', 'gateway'"
  type        = string
  default     = "application"
}
variable "drop_invalid_header_alb" {
  description = "Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false)."
  type        = bool
  default     = false
}
variable "timeout_idle_alb" {
  description = "The time in seconds that the connection is allowed to be idle. Only valid for Load Balancers of type application."
  type        = number
  default     = 60
}
variable "enable_cross_zone_load_balancing_nlb" {
  description = "Cross zone load balancing needs to be enalbed or not.. only for NLB"
  type        = bool
  default     = false
}

######################################################
## Data to fetch VPC details
######################################################

data "aws_vpc" "vpc_selected" {
  filter {
    name   = "tag:Name"
    values = ["puneet_vpc"]
  }
}

###################################################################
## Data to be fetched for subnets
##################################################################
data "aws_subnets" "private1" {
  # vpc_id = data.aws_vpc.vpc_selected.id
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["puneet_public_subnet_az_1*"]
  }
}

# data "aws_subnet" "private" {
#   for_each = data.aws_subnets.private1.ids
#   id       = each.value
# }




###################################################################
## Application Load Balancer
##################################################################

resource "aws_lb" "applications_load_balancer" {
  name                             = var.application_load_balancer_name
  internal                         = var.internal_or_internet_facing
  load_balancer_type               = var.loadBalancer_type
  security_groups                  = data.aws_security_groups.sg.ids
  drop_invalid_header_fields       = var.drop_invalid_header_alb
  idle_timeout                     = var.timeout_idle_alb
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing_nlb
  # subnets                          = [for s in data.aws_subnet.private : s.id]
  subnets                          = data.aws_subnets.private1.ids

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }
  tags = {
    Environment = var.alb_environment_tag
  }
}



resource "aws_launch_configuration" "lc" {
  name_prefix   = "lc"
  image_id      = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  user_data     = file("${path.module}/user-data.sh")
  associate_public_ip_address = true
  iam_instance_profile = "EC2CodedeployRole"
  security_groups = data.aws_security_groups.sg.ids
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  depends_on = [
    aws_lb.applications_load_balancer
  ]
  name                      = "ec2_production"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  launch_configuration      = aws_launch_configuration.lc.name
  # vpc_zone_identifier       = [for s in data.aws_subnet.private : s.id]
  vpc_zone_identifier       = data.aws_subnets.private1.ids


  timeouts {
    delete = "20m"
  }

  tag {
    key                 = "Name"
    value               = "ec2_production"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn   = aws_lb_target_group.alb_target_group.arn
}



#############################################################
## Redirect Action
#############################################################
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.applications_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    type             = "forward"
  }
}

######################################################
## Instance Target Group
######################################################

resource "aws_lb_target_group" "alb_target_group" {
  name     = "tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc_selected.id
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
  tags = {
    "Name" = "tg"
  }
}