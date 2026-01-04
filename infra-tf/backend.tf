terraform {
  backend "s3" {
    bucket         = "tnt-eu-observability-dev-tf"
    key            = "tnt-eu-observability-dev-tf.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tnt-eu-observability-dev-tf-locks"
    encrypt        = true
  }
}