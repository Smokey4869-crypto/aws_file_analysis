provider "aws" {
  region = var.aws_region
}

resource "random_id" "unique_id" {
  byte_length = 4
}

# Call S3 Module
module "s3_bucket" {
  source      = "./modules/s3"
  bucket_name = "file-uploader-bucket-${random_id.unique_id.hex}"
  queue_arn   = module.sqs_queue.queue_arn
}

# Call SQS Module
module "sqs_queue" {
  source     = "./modules/sqs"
  queue_name = "file-processing-queue"
  bucket_arn = module.s3_bucket.bucket_arn
}

# Call Lambda Module
module "lambda_function" {
  source          = "./modules/lambda"
  lambda_name     = "process-file-function"
  s3_bucket_arn   = module.s3_bucket.bucket_arn
  sqs_queue_url   = module.sqs_queue.queue_url
  sqs_queue_arn   = module.sqs_queue.queue_arn
  lambda_zip_path = "./modules/data/lambda_code/lambda_function.zip"
  bucket_name     = module.s3_bucket.bucket_name
  dlq_arn         = module.sqs_queue.dlq_arn
  aws_region      = var.aws_region
}

# Call CloudWatch Alarms Module
module "cloudwatch_alarms" {
  source               = "./modules/cloudwatch_alarms"
  lambda_function_name = module.lambda_function.function_name
  sqs_queue_name       = module.sqs_queue.queue_name
}
