terraform {
  backend "gcs" {
    bucket = "storage-bucket-eugenesable"
    prefix = "terraform/prod"
  }
}
