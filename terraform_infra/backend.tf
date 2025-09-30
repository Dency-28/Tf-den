terraform {
  backend "s3" {
    bucket = "tf-state-dency"
    key    = "terraform.tfstate"
    region = "ap-south-1"
  }
}
