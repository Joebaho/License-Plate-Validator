terraform {
  backend "s3" {
    bucket  = "validator-license-bucket01"
    key     = "terraform-state-file/license-plate"
    region  = "us-west-2"
    encrypt = true
  }
}
