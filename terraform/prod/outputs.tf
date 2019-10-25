output "app_external_ip" {
  value = module.app.app_external_ip
}

output "mongo_ip" {
  value = "${module.db.internal_ip}"
}


