# ✅ Generate random suffix so S3 & DynamoDB are unique
resource "random_id" "suffix" {
  byte_length = 4
}

# ✅ Create S3 bucket for remote backend
resource "aws_s3_bucket" "tf_state" {
  bucket        = "tf-state-dency-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "Terraform State Bucket"
  }
}

# ✅ Enable versioning
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ✅ Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ✅ Create DynamoDB table for locks
resource "aws_dynamodb_table" "tf_locks" {
  name         = "tf-state-locks-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock Table"
  }
}

# ✅ Outputs (used later in infra init)
output "tf_state_bucket" {
  value = aws_s3_bucket.tf_state.bucket
}

output "tf_state_lock_table" {
  value = aws_dynamodb_table.tf_locks.name
}
