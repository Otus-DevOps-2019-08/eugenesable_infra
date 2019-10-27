variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable zone {
  description = "Zone for instance"
  default     = "europe-west1-b"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable mongo_ip {
  description = "IP MongoDB"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}


