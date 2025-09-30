terraform {
  backend "s3" {
    bucket         = "tf-state-dency"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
