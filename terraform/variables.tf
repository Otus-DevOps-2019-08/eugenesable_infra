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
  description = "Path to the public key used for ssh access"
}
variable public_key_path1 {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable public_key_path2 {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable disk_image {
  description = "Disk image"
}

variable private_key_path {
  description = "Path to the private key used for ssh conection"
}

variable zone {
  description = "Zone for instance"
  default     = "europe-west1-b"
}

variable instances_count {
  description = "Count of instances"
  default     = 1
}
