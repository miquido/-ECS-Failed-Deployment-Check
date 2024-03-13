data "aws_caller_identity" "default" {}
data "aws_region" "default" {}


locals {
  ecs_error_detector_lambda_name         = "${var.project}-${var.environment}-ecs_error_detector"
  ecs_error_detector_lambda_zip_filename = "${path.module}/ecs_error_detector.zip"
}

data "archive_file" "ecs_error_detector" {
  type             = "zip"
  source_file      = "${path.module}/main.py"
  output_path      = local.ecs_error_detector_lambda_zip_filename
  output_file_mode = "0755"
}

resource "aws_lambda_function" "ecs_error_detector" {
  function_name    = local.ecs_error_detector_lambda_name
  role             = aws_iam_role.ecs_error_detector.arn
  filename         = local.ecs_error_detector_lambda_zip_filename
  handler          = "main.lambda_handler"
  runtime          = "python3.9"
  timeout          = 3
  memory_size      = 128
  tags             = var.tags
  source_code_hash = data.archive_file.ecs_error_detector.output_base64sha256

  depends_on = [
    aws_iam_role.ecs_error_detector,
    aws_cloudwatch_log_group.ecs_error_detector
  ]
  environment {
    variables = {
      ECS_CLUSTER   = var.ecs_cluster_id
      SNS_TOPIC_ARN = var.sns_topic_arn

    }
  }
}

resource "aws_cloudwatch_log_group" "ecs_error_detector" {
  name              = "/aws/lambda/${local.ecs_error_detector_lambda_name}"
  retention_in_days = var.log_retention
  tags              = var.tags
}


################################################
#### IAM                                    ####
################################################

resource "aws_iam_role" "ecs_error_detector" {
  name               = "${local.ecs_error_detector_lambda_name}-role"
  description        = "Role used for lambda function ${local.ecs_error_detector_lambda_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_ecs_error_detector.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "ecs_error_detector" {
  name   = "${local.ecs_error_detector_lambda_name}-policy"
  policy = data.aws_iam_policy_document.role_ecs_error_detector.json
  role   = aws_iam_role.ecs_error_detector.id
}

data "aws_iam_policy_document" "assume_role_ecs_error_detector" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "role_ecs_error_detector" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.ecs_error_detector.arn}*"
    ]
  }

  statement {
    actions = [
      "ecs:ListServices",
      "ecs:DescribeServices"
    ]

    resources = [
      "arn:aws:ecs:${data.aws_region.default.id}:${data.aws_caller_identity.default.account_id}:service/${var.ecs_cluster_id}/*"
    ]
  }

  statement {
    actions = [
      "SNS:Publish"
    ]

    resources = [
      var.sns_topic_arn
    ]
  }

}

resource "aws_cloudwatch_event_rule" "run_check" {
  name                = "${var.project}-${var.environment}-run-check"
  schedule_expression = var.check_cron
  is_enabled          = true
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "run_check" {
  rule = aws_cloudwatch_event_rule.run_check.name
  arn  = aws_lambda_function.ecs_error_detector.arn
}

resource "aws_lambda_permission" "run_check" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_error_detector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.run_check.arn
}