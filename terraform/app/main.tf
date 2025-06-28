provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "${var.project_name}-test-bucket-123456"
  
  tags = {
    Name        = "${var.project_name}-test-bucket"
    Environment = "development"
    Purpose     = "testing-terraform-permissions"
  }
}