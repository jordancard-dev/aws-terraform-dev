# Output variable definitions

output "arn" {
  description = "ARN of the bucket"
  value       = aws_s3_bucket.collection_s3_bucket.arn
}

output "name" {
  description = "Name (id) of the bucket"
  value       = aws_s3_bucket.collection_s3_bucket.id
}


