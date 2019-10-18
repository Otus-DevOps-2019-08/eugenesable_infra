variable project {
  description = "Project ID"
}
variable region {
  description = "Region"
  # Значение по умолчанию
  default = "europe-west1"
}
variable public_key_path {
  # Описание переменной
  description = "Public key path"
}
variable disk_image {
  description = "Disk image"
}

variable private_key_path {
  description = "Private key path"
}

variable zone {
  description = "Zone for instance"
  default     = "europe-west1-b"
}

variable instances {
  description = "Instances counter"
  default     = 1
}

