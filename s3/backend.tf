terraform {
  backend "s3" {
    bucket         = "tech-2026-tfstate"
    key            = "dev/s3.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    
    # Enable new native locking
    use_lockfile   = true 

  }
}
