terraform {
  backend "s3" {
    bucket         = "wezvatech-2026-tfstate"
    key            = "product-name/envs/prod/s3.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    
    # Enable new native locking
    use_lockfile   = true 

  }
}
