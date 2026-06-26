terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
# S3バケット
resource "aws_s3_bucket" "raw_data" {
  bucket = "portfolio-01-osaka-weather-raw-2026-tetsu"
}

# バージョニング有効化
resource "aws_s3_bucket_versioning" "raw_data_versioning" {
  bucket = aws_s3_bucket.raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# サーバーサイド暗号化（SSE-S3）
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data_encryption" {
  bucket = aws_s3_bucket.raw_data.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ライフサイクルルール（Athena結果の自動削除）
resource "aws_s3_bucket_lifecycle_configuration" "raw_data_lifecycle" {
  bucket = aws_s3_bucket.raw_data.id
  rule {
    id     = "delete-athena-results"
    status = "Enabled"
    filter {
      prefix = "athena-results/"
    }
    expiration {
      days = 1
    }
    # 非現行バージョンの削除も追加
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

# Lambda実行ロール
resource "aws_iam_role" "lambda_role" {
  name = "osaka-weather-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda基本ポリシー（CloudWatch Logs書き込み）
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda用S3書き込みポリシー
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "S3PutObjectForWeather"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::portfolio-01-osaka-weather-raw-2026-tetsu/*"
      }
    ]
  })
}

# Lambda関数
resource "aws_lambda_function" "weather_fetcher" {
  function_name = "osaka-weather-fetcher"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30

  s3_bucket = aws_s3_bucket.raw_data.id
  s3_key    = "lambda/lambda_function.zip"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.raw_data.id
    }
  }
}

# EventBridgeルール
resource "aws_cloudwatch_event_rule" "weather_schedule" {
  name                = "osaka-weather-daily-fetch"
  description         = "大阪の天気をデイリーで取得"
  schedule_expression = "cron(0 22 * * ? *)"
}

# EventBridgeターゲット（Lambda）
resource "aws_cloudwatch_event_target" "weather_target" {
  rule      = aws_cloudwatch_event_rule.weather_schedule.name
  target_id = "WeatherLambdaTarget"
  arn       = aws_lambda_function.weather_fetcher.arn
}

# LambdaにEventBridgeからの実行許可
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weather_fetcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weather_schedule.arn
}
