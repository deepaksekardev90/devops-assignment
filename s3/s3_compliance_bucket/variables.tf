variable "bucket_names" {
  type        = list(string)
  description = "A list of unique S3 bucket name strings to create and apply compliance policies against"
}

variable "environment" {
  type        = string
  description = "Deployment environment namespace prefix (e.g. production, staging)"
  default     = "production"
}

