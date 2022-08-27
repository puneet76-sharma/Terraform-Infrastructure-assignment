resource "aws_sns_topic" "user_updates" {
  name = "mycode755"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = "<MAIL ID>"
}   

resource "aws_cloudwatch_event_rule" "console" {
  name        = "capture-aws-sign-in"
  description = "Capture each AWS Console Sign In"

  event_pattern = <<EOF
{
  "source": ["aws.ec2"]
}
EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.console.name
  target_id = aws_sns_topic.user_updates.name
  arn       = aws_sns_topic.user_updates.id
}
