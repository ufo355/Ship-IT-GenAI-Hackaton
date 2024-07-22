terraform {
  backend "s3" {
    bucket  = ""
    encrypt = false
    key     = "terraform-rag.tfstate"
    region  = ""
  }
}
