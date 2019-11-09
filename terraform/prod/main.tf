provider "google" {
  version = "~> 2.15"
  project = var.project
  region  = var.region
}

module "app" {
  source           = "../modules/app"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  zone             = var.zone
  app_disk_image   = var.app_disk_image
  mongo_ip         = module.db.mongo_ip
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  zone             = var.zone
  db_disk_image    = var.db_disk_image
}

module "vpc" {
  source           = "../modules/vpc"
  project          = var.project
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  source_ranges    = ["188.187.106.213/32"]
}






