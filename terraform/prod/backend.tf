terraform {
  backend "gcs" {
    bucket = "storage-bucket-eugenesable-1"
    prefix = "terraform/prod"
  }
}


