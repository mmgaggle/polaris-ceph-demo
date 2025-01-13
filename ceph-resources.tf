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

# Account ARN
variable "account_arn" {
  description = "Account ARN to use in IAM resources"
  default     = "RGW12345678901234567"
}

# Catalog Location
variable "location" {
  description = "Location for catalog, eg. s3://polaris"
  default     = "s3://polaris"
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

# Create IAM user catalog admin
resource "aws_iam_user" "catalog_admin" {
  name = "admin"
  path = "/polaris/catalog/"
}

# Create Access Key for catalog admin
resource "aws_iam_access_key" "catalog_admin_key" {
  user = aws_iam_user.catalog_admin.name
}

output "admin_access_key" {
  value = aws_iam_access_key.catalog_admin_key.id
  description = "Catalog admin access key"
}

output "admin_secret_key" {
  value = aws_iam_access_key.catalog_admin_key.secret
  description = "Catalog admin secret key"
  sensitive   = true
}


# Create IAM role catalog_client
resource "aws_iam_role" "catalog_client_role" {
  name               = "client"
  path               = "/polaris/catalog/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          AWS: format("arn:aws:iam::%s:user/polaris/catalog/admin",var.account_arn)
        }
        Effect    = "Allow"
      }
    ]
  })
}

# IAM Policy for limited S3 bucket access (for client role/user)
resource "aws_iam_role_policy" "catalog_client_policy" {
  name        = "catalog_client_policy"
  role        = "client"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:*"]
        Effect   = "Allow"
        Resource = [
          format("arn:aws:s3:::%s/*",var.bucket_name),
          format("arn:aws:s3:::%s",var.bucket_name)
        ]
      }
    ]
  })
}

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_image" "polaris" {
  name         = "icr.io/ceph-polaris/polaris:latest"
  keep_locally = false
}

resource "docker_container" "polaris" {
  image = docker_image.polaris.image_id
  name  = "polaris"
  ports {
    internal = 8181
    external = 8181
  }
  env = [
    "AWS_ACCESS_KEY_ID=${aws_iam_access_key.catalog_admin_key.id}",
    "AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.catalog_admin_key.secret}",
    format("ENDPOINT_URL=%s",var.ceph_endpoint),
    format("LOCATION=%s",var.location)
  ]
}
