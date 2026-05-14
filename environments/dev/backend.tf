# Local backend per environment.
# State files live next to the env so dev/staging/prod stay isolated.
# Swap this file's contents (or use a backend override) when moving to S3/MinIO/etc.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
