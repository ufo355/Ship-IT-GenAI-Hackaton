terraform {
  backend "s3" {
    bucket  = ""
    encrypt = false
    key     = "terraform-lex.tfstate"
    region  = ""
  }
}
