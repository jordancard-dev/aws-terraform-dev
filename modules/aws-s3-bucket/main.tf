
###################################
# S3 Bucket
###################################
resource "aws_s3_bucket" "collection_s3_bucket" {
  bucket = var.bucket_name
  versioning {
    enabled = var.versioning
  }
}

###################################
# IAM Policy Document
###################################

data "aws_iam_policy_document" "collection_s3_bucket_policy_doc" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.collection_s3_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_bucket_oai.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.collection_s3_bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.s3_bucket_oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "collection_s3_bucket_policy" {
  bucket = aws_s3_bucket.collection_s3_bucket.bucket
  policy = data.aws_iam_policy_document.collection_s3_bucket_policy_doc.json
}


################################
# S3 Bucket Public Access Block
################################
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.collection_s3_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  # depends_on              = [time_sleep.wait_30_seconds]
}



#############
# CloudFront
#############
resource "aws_cloudfront_distribution" "cloudfront" {

  enabled             = true
  default_root_object = "index.html"
  aliases             = [] # (Required) For HTTPS Requirement, must be DNS Validated & dns name must Only associated be associated with single distribution in single aws account.

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"] # "DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.collection_s3_bucket.bucket
    viewer_protocol_policy = "redirect-to-https" # redirect-to-https # https-only # allow-all


    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
    compress    = true



    forwarded_values {
      query_string = true

      headers = [
        "Origin"
      ]

      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.collection_s3_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.collection_s3_bucket.bucket

    custom_header {
      name  = "*"
      value = "*"
    }

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_bucket_oai.cloudfront_access_identity_path
    }

  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = var.cert_arn # ACM Cert Arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

###################################
# CloudFront Origin Access Identity
###################################
resource "aws_cloudfront_origin_access_identity" "s3_bucket_oai" {
  comment = "s3_bucket_oai"
}

