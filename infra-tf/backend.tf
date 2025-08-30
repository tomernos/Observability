terraform {
  backend "s3" {
    bucket = "tnt-eu-observability-dev-tf"
    key    = "tnt-eu-observability-dev-tf.tfstate"
    region = "eu-central-1"
  }
}