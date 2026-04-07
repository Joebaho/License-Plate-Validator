terraform {
  backend "s3" {
    bucket  = "licenses-plate-bucket"
    key     = "terraform-state-file/license-plate"
    region  = "us-west-2"
    encrypt = true
  }
}