# Define Ceph S3 and STS endpoint URIs
variable "ceph_endpoint" {
  description = "Ceph S3/STS endpoint URI"
  default     = null
}

# Define credentials path and profile name
variable "credentials_path" {
  description = "Credentials path"
  default     = "/home/kyle/.aws/credentials"
}

variable "credentials_profile" {
  description = "Name of credentials profile"
  default     = "polaris-root"
}

# Define bucket name for Polaris catalog
variable "bucket_name" {
  description = "Bucket name for Polaris catalog"
  default     = "polaris"
}

# Provider configuration
provider "aws" {
  region = "default"
  skip_credentials_validation = true
  skip_region_validation = true
  shared_credentials_files = [var.credentials_path]
  profile = var.credentials_profile

  endpoints {
    s3 = var.ceph_endpoint
    sts = var.ceph_endpoint
    iam = var.ceph_endpoint
  }
}

output "bucket_arn" {
  value = "${aws_s3_bucket.catalog_bucket.arn}"
}

# Create S3 bucket
resource "aws_s3_bucket" "catalog_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "CatalogBucket"
    Environment = "Production"
  }
}

# Create IAM user catalog_admin
resource "aws_iam_user" "catalog_admin" {
  name = "catalog_admin"
}

# Create IAM user catalog.client
resource "aws_iam_user" "catalog_client_user" {
  name = "catalog_client"
}

# Create IAM role catalog.client
resource "aws_iam_role" "catalog_client_role" {
  name               = "catalog.client"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
      }
    ]
  })
}
