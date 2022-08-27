
data "aws_subnets" "example" {
  # vpc_id = data.aws_vpc.vpc_available.id
    filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc_available.id]
  }
}

# data "aws_subnet" "example" {
#   for_each = data.aws_subnets.example.ids
#   id       = each.value
# }

data "aws_security_group" "puneet_sg" {
  filter {
    name   = "tag:Name"
    values = ["puneet_security_group"]
  }
}


variable "log_group_name" {
  type        = string
  description = "log group name"
  default     = "log-group"
}

variable "log_stream_name" {
  type        = string
  description = "log stream name"
  default     = "log-stream"
}

variable "s3_bucket_log" {
  type        = string
  description = "s3 bucket name to store logs"
  default     = "puneet-s3"
}

variable "s3_bucket_artifact" {
  type        = string
  description = "s3 bucket to store artifacts"
  default     = "puneet-s3"
}


resource "aws_iam_role" "codebuild_role" {
  name = "codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "iam_policy" {
  role = aws_iam_role.codebuild_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY
}



resource "aws_codebuild_project" "codebuild_project" {
  count         = 1
  name          = var.codebuild_project_name
  description   = "build project"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type     = "CODEPIPELINE"
  }


  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.log_group_name
      stream_name = var.log_stream_name
    }

    s3_logs {
      status   = "ENABLED"
      location = "${var.s3_bucket_log}/build-log"
    }
  }
  source {
    type      = "CODEPIPELINE"
  }
  tags = {
    Environment = "dev"
  }
}