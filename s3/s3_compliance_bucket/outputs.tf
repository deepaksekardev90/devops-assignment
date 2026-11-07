output "bucket_arns" {
  value       = { for k, b in aws_s3_bucket.compliance_bucket : k => b.arn }
  description = "A mapped directory of generated S3 bucket names and their unique AWS resource identifiers"
}

