output "bucket_arns" {
  value       = { for k, b in aws_s3_bucket.compliance_bucket : k => b.arn }
  description = "A mapped directory of generated S3 bucket names and their unique AWS resource identifiers"
}

output "replica_bucket_arns" {
  value       = { for k, b in aws_s3_bucket.replica : k => b.arn }
  description = "Map of source bucket name to the ARN of its replica bucket in the destination region"
}

output "replication_role_arn" {
  value       = try(aws_iam_role.replication[0].arn, null)
  description = "ARN of the IAM role S3 uses to replicate objects (null when replication is disabled)"
}
