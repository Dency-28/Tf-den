# --- Commented out because backend already exists ---
# resource "aws_s3_bucket" "tf_state" {
#   bucket = "tf-state-dency"  # Must be globally unique
#   force_destroy = true
#
#   tags = {
#     Name = "Terraform State Bucket"
#   }
# }
#
# resource "aws_s3_bucket_versioning" "tf_state_versioning" {
#   bucket = aws_s3_bucket.tf_state.id
#
#   versioning_configuration {
#     status = "Enabled"
#   }
# }
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
#   bucket = aws_s3_bucket.tf_state.id
#
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }
#
# resource "aws_dynamodb_table" "tf_locks" {
#   name         = "tf-state-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
#
#   tags = {
#     Name = "Terraform State Lock Table"
#   }
# }

# --- Keep backend block as is ---
terraform {
  backend "s3" {
    bucket        = "tf-state-dency"
    key           = "terraform.tfstate"
    region        = "us-east-1"
    dynamodb_table = "tf-state-locks"
    encrypt       = true
  }
}
