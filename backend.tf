terraform {
  backend "s3" {
    bucket         = "continuum-tfstate-458781646101"
    key            = "continuum/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "continuum-terraform-locks"
    encrypt        = true
  }
}
