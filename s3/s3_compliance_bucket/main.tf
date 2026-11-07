# 1. Dynamically provision the core bucket assets using set interpolation loops
resource "aws_s3_bucket" "compliance_bucket" {
  # Converts list to a set to guarantee item uniqueness and enable safe index looping
  for_each = toset(var.bucket_names)
  bucket   = each.value

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform-Platform-Engine"
  }
}

# 2. Bind strict versioning rules to every generated bucket resource
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each = var.enable_versioning ? aws_s3_bucket.compliance_bucket : {}
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Inject your targeted enterprise lifecycle configuration rules
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  for_each = var.enable_lifecycle ? aws_s3_bucket.compliance_bucket : {}
  bucket   = each.value.id

  # Versioning must exist before noncurrent-version rules are meaningful
  depends_on = [aws_s3_bucket_versioning.bucket_versioning]

  rule {
    id     = "platform-compliance-lifecycle-policy"
    status = "Enabled"

    # Tier 1: Transition raw objects to Infrequent Access after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Tier 2: 🎯 FIX: Move to Glacier archiving after exactly 6 months (180 days)
    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    # Tier 3: Permanent clean expiration of live objects after 2 years (730 days)
    expiration {
      days = 730
    }

    # Tier 4: Manage older, noncurrent tracking versions of your objects
    # Noncurrent-version rules only apply when versioning is enabled
    dynamic "noncurrent_version_transition" {
      for_each = var.enable_versioning ? [1] : []
      content {
        noncurrent_days = 90
        storage_class   = "GLACIER"
      }
    }

    dynamic "noncurrent_version_expiration" {
      for_each = var.enable_versioning ? [1] : []
      content {
        noncurrent_days = 180
      }
    }
  }
}

