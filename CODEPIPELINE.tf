variable "codepipeline_name" {
  type = string
  default = "pipeline"
}
variable "build_stage" {
  type    = string
  default = false
}
variable "source_repo_name" {
  description = "Enter the source repository name with Organization name"
  type        = string
  default     = ""
}

variable "branch_name" {
  description = "Branch name"
  type        = string
  default     = "main"
}

variable "codebuild_project_name" {
  description = "Enter the codebuild project name"
  type        = string
  default     = "codebuild_test"

}

variable "target_region" {
  description = "Enter the region name where the action needs to be taken"
  type        = string
  default     = "us-east-1"
}



resource "aws_codepipeline" "codepipeline" {
  name     = var.codepipeline_name
  role_arn = "arn:aws:iam::106118286702:role/service-role/AWSCodePipelineServiceRole-us-east-1-my_pipeline_manual"

  artifact_store {
    # location = data.aws_s3_bucket.s3_bucket_artifact_store.id
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }
  ################################################################
  ## Source Stage
  ################################################################
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = "arn:aws:codestar-connections:us-east-1:106118286702:connection/69cb6108-a4b3-4dfb-a294-9401e4e38290"
        FullRepositoryId = "puneet76-sharma/spring-boot-rds-for-terraform"
        BranchName       = "master"
      }
    }
  }
  ################################################################
  ## Build Stage
  ################################################################
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = "codebuild_test"
      }
    }
  }
  ################################################################
  ## Deploy Stage
  ################################################################
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      version         = "1"
      run_order       = "1"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      region          = var.target_region
      configuration = {
        ApplicationName     = var.codedeploy_app_and_group_name
        DeploymentGroupName = var.codedeploy_app_and_group_name
      }
    }
  }


}


# resource "aws_iam_role" "codepipeline_role" {
#   name = "test-role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "codepipeline.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
# }

# resource "aws_iam_role_policy" "codepipeline_policy" {
#   name = "codepipeline_policy"
#   role = aws_iam_role.codepipeline_role.id

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect":"Allow",
#       "Action": [
#         "s3:GetObject",
#         "s3:GetObjectVersion",
#         "s3:GetBucketVersioning",
#         "s3:PutObjectAcl",
#         "s3:PutObject"
#       ],
#       "Resource": [
#         "${aws_s3_bucket.codepipeline_bucket.arn}",
#         "${aws_s3_bucket.codepipeline_bucket.arn}/*"
#       ]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "codestar-connections:UseConnection"
#       ],
#       "Resource": "arn:aws:codestar-connections:us-east-1:106118286702:connection/69cb6108-a4b3-4dfb-a294-9401e4e38290"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "codebuild:BatchGetBuilds",
#         "codebuild:StartBuild"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }


resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "test-bucket-7696"
}