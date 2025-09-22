# Random Suffix for bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Frontend S3 bucket
resource "aws_s3_bucket" "Frontend" {
  bucket = "${var.project_name}-frontend-bucket-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-frontend"
    Type = "frontend"
  })
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.Frontend.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Backend s3 bucket
resource "aws_s3_bucket" "Backend" {
  bucket = "${var.project_name}-backend-bucket-${random_id.bucket_suffix.hex}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backend"
    Type = "backend"
  })
}

resource "aws_s3_bucket_public_access_block" "backend" {
  bucket = aws_s3_bucket.Backend.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Upload backend.zip to backend bucket
resource "aws_s3_object" "backend_zip" {
  bucket = aws_s3_bucket.Backend.id
  key    = "backend-deployment-fixed.zip"
  source = "${path.root}/../backend-deployment-fixed.zip"
  etag   = filemd5("${path.root}/../backend-deployment-fixed.zip")

  tags = merge(var.tags, {
    Name = "backend-deployment"
  })
}

# Upload build folder contents to frontend bucket
resource "aws_s3_object" "frontend_build" {
  for_each = fileset("${path.root}/../build", "**/*")

  bucket = aws_s3_bucket.Frontend.id
  key    = each.value
  source = "${path.root}/../build/${each.value}"
  etag   = filemd5("${path.root}/../build/${each.value}")

  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "json" = "application/json"
    "ico"  = "image/x-icon"
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")

  tags = merge(var.tags, {
    Name = "frontend-build"
  })
}
