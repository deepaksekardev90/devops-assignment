locals {
  # Empty set when replication is off, so every replica resource below creates nothing
  replication_buckets = var.enable_replication ? toset(var.bucket_names) : toset([])
}

# ===========================================================================
# SOURCE BUCKETS
# ===========================================================================

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
  for_each = aws_s3_bucket.compliance_bucket
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Block all public access on every bucket
resource "aws_s3_bucket_public_access_block" "bucket_pab" {
  for_each = aws_s3_bucket.compliance_bucket
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Inject your targeted enterprise lifecycle configuration rules
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  for_each = aws_s3_bucket.compliance_bucket
  bucket   = each.value.id

  # Noncurrent-version rules need versioning to exist first
  depends_on = [aws_s3_bucket_versioning.bucket_versioning]

  rule {
    id     = "platform-compliance-lifecycle-policy"
    status = "Enabled"

    # Apply to every object in the bucket
    filter {}

    # Tier 1: Transition raw objects to Infrequent Access after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Tier 2: Move to Glacier archiving after exactly 6 months (180 days)
    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    # Tier 3: Permanent clean expiration of live objects after 2 years (730 days)
    expiration {
      days = 730
    }

    # Tier 4: Manage older, noncurrent tracking versions of your objects
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}

# ===========================================================================
# DESTINATION (REPLICA) BUCKETS - created in the destination region
# ===========================================================================

resource "aws_s3_bucket" "replica" {
  provider = aws.destination
  for_each = local.replication_buckets
  bucket   = "${each.value}${var.destination_bucket_suffix}"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform-Platform-Engine"
    Role        = "replication-destination"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.destination
  for_each = aws_s3_bucket.replica
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled" # required on the destination for replication
  }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.destination
  for_each = aws_s3_bucket.replica
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===========================================================================
# IAM ROLE S3 ASSUMES TO REPLICATE (one role shared by all buckets)
# ===========================================================================

data "aws_iam_policy_document" "replication_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  count              = var.enable_replication ? 1 : 0
  name               = "compliance-s3-replication-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [for b in aws_s3_bucket.compliance_bucket : b.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = [for b in aws_s3_bucket.compliance_bucket : "${b.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = [for b in aws_s3_bucket.replica : "${b.arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  count  = var.enable_replication ? 1 : 0
  name   = "compliance-s3-replication-policy-${var.environment}"
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  count      = var.enable_replication ? 1 : 0
  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}

# ===========================================================================
# REPLICATION RULES (configured on each source bucket)
# ===========================================================================

resource "aws_s3_bucket_replication_configuration" "this" {
  for_each = local.replication_buckets

  # Versioning must be enabled on BOTH sides before replication is created
  depends_on = [
    aws_s3_bucket_versioning.bucket_versioning,
    aws_s3_bucket_versioning.replica,
    aws_iam_role_policy_attachment.replication,
  ]

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.compliance_bucket[each.key].id

  rule {
    id     = "replicate-all-objects"
    status = "Enabled"

    filter {} # empty filter = replicate every object

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.replica[each.key].arn
      storage_class = var.replica_storage_class
    }
  }
}
