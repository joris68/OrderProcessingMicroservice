terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1" # for the best latency
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  stage_name        = "developement"
  stage_description = "my Deployment Stage"

  lifecycle {
    create_before_destroy = true
  }

}


resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    TestAssignment = "true"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "AddOrders" {
  function_name = "AddOrders"

  # Replace with the path to your ZIP file
  filename      = "C:\\Users\\jojog\\Documents\\Archiv\\Studium\\GitHub\\TestAssignmentScalable\\TestAssignmentScalable\\Lambdas\\AddOrder.zip"
  handler       = "AddOrder.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.10" 

  environment {
    variables = {
      Q_URL = aws_sqs_queue.orders_queue_fifo.url
    }
  }

  tags = {
    TestAssignment = "true"
  }
}

resource "aws_lambda_function" "ProcessOrders" {
  function_name = "ProcessOrders"

  # Replace with the path to your ZIP file
  filename      = "C:\\Users\\jojog\\Documents\\Archiv\\Studium\\GitHub\\TestAssignmentScalable\\TestAssignmentScalable\\Lambdas\\ProcessOrder.zip"
  handler       = "ProcessOrder.lambda_handler" # Adjust based on your handler's name and entry point
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.10" # Updated runtime to Python 3.10

  tags = {
    TestAssignment = "true"
  }
}

resource "aws_sqs_queue" "orders_queue_fifo" {
  name                        = "orders-queue.fifo"
  visibility_timeout_seconds  = 30
  fifo_queue                  = true
  content_based_deduplication = true

  tags = {
    TestAssignment = "true"
  }
}


resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_sqs_policy"
  description = "IAM policy for Lambda functions to interact with SQS queues"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
        ],
        Resource = aws_sqs_queue.orders_queue_fifo.arn,
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}


resource "aws_api_gateway_rest_api" "api" {
  name        = "OrdersAPI"
  description = "API Gateway for Orders"

  tags = {
    TestAssignment = "true"
  }
}



resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.api_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.AddOrders.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.AddOrders.function_name
  principal     = "apigateway.amazonaws.com"

  #source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"
}

# allows that lambda function "processOrders" can be triggered from SQS
resource "aws_lambda_permission" "allow_sqs_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ProcessOrders.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.orders_queue_fifo.arn
}

# event source mapping so the lambda funtion listens to the SQS queue
resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.orders_queue_fifo.arn
  function_name    = aws_lambda_function.ProcessOrders.arn
  batch_size       = 1
}



