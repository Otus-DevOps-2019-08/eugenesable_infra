# eugenesable_infra
eugenesable Infra repository

# Google Cloud Platform

# Выполнено задание №7
 
 - Ветка terraform-2
 - Установлено количество инстансов app равным 1
 - Перенесен файл lb.tf в terraform/files
 - Подняли инфраструктуру из прошлого ДЗ ```terraform apply```
 - Просмотр провил файрвола: ```gcloud compute firewall-rules list```
 - Добавлено правило файрвола "default-allow-ssh" в main.tf. При apply вылезла ошибка, говорящая о том, что правило не известно терраформу 
 - Импортирован созданное ранее руками правило для всей сети "default" в текущий state "default-allow-ssh"
```
terraform import google_compute_firewall.firewall_ssh default-allow-ssh
```
 - Задан ip для app:
```
resource "google_compute_address" "app_ip" {
name = "reddit-app-ip"
}
```
 - Ip добавлен в ресурс:
```
access_config {
nat_ip = google_compute_address.app_ip.address
}
```
 - Созданы отдельные образы для db и app с помощью packer'а:
```
packer build -var 'project_id=infra-******' -var 'source_image_family=ubuntu-1604-lts' -var 'machine_type=f1-micro' -var 'disk_size=10' app.json
packer build -var 'project_id=infra-******' -var 'source_image_family=ubuntu-1604-lts' -var 'machine_type=f1-micro' -var 'disk_size=10' db.json 
```
 - Из main.tf созданы отдельные конфиги app.tf, db.tf, vpc.tf, в которых находятся соответсвующие описания 
 - Добавлены переменные "app_disk_image" в variables.tf для создания соответствующего образа
 - Создана папка modules/ и туда помещены приготовленные ранее конфиги (app.tf -> modules/app/main.tf, db.tf -> modules/db/main.tf, vpc.tf -> modules/vpc/main.tf) и переменные (variables.tf, outputs.tf)
 - В основной main.tf добавлено обращение к ранее создвнным модулям:
```
module "app" {
  source = "modules/app"
  public_key_path = var.public_key_path
  zone = var.zone
  app_disk_image = var.app_disk_image
}
module "db" {
  source = "modules/db"
  public_key_path = var.public_key_path
  zone = var.zone
  db_disk_image = var.db_disk_image
}
module "vpc" {
  project         = var.project
  public_key_path = var.public_key_path
  source          = "../modules/vpc"
  source_ranges   = ["0.0.0.0/0"]
}
```
 - Загружены созданные модули:  ```terraform get```
 - Параметризирован модуль vpc за счет input-переменной "source_ranges":
```
resource "google_compute_firewall" "firewall_ssh" {
  name = "default-allow-ssh"
  network = "default"
  allow {
   protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = var.source_ranges
}
  - Переменная вынесена в variables.tf:
```
variable source_ranges {
  description = "Allowed IP addresses"
  default     = ["0.0.0.0/0"]
}
```
 - Проверен доступ путем подстановки собственного ip-адреса. При подстановке "чужога" адреса доступа нет. После apply праавило появляется в веб-интерсфейсе gcp

 Самостоятельное задание:
 - Созданы 2 окружения stage и prod: на prod открыт доступ только с собственного ip-адреса, stage - для всех
 - Добавлен модуль "storage-bucket":
```
provider "google" {
  version = "~> 2.15"
  project = var.project
  region  = var.region
}

module "storage-bucket" {
  source  = "SweetOps/storage-bucket/google"
  version = "0.3.0"

  # Имя поменяйте на другое
  name = "storage-bucket-eugenesable"
  location = var.region
}

output storage-bucket_url {
  value = module.storage-bucket.url
}
```
 - Посмотреть список бакетов:
```
gsutil ls
gs://storage-bucket-eugenesable/
```
 - Настроено хранение state в удаленном бэкенде: https://www.terraform.io/docs/backends/types/gcs.html
 - Добавлено 2 файла: prod/backend.tf и stage/backend.tf
```
terraform {
  backend "gcs" {
    bucket  = "storage-bucket-eugenesable"
    prefix  = "terraform/prod"
  }
}
```
```
terraform {
  backend "gcs" {
    bucket  = "storage-bucket-eugenesable"
    prefix  = "terraform/stage"
  }
}
```
 - Добавлены провиженеры в модули для развертывания приложения:
 - app:
 - Загружаем в папку tmp/ сервис puma.service, находящийся в папке модуля
```
provisioner "file" {
    source      = "${path.module}/files/puma.service"
    destination = "/tmp/puma.service"
  }
```
 - Диплой приложения
```
  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
```
 - Записываем бд в локальную переменную окружения
```
  provisioner "remote-exec" {
    inline = ["echo export DATABASE_URL=\"${var.mongo_ip}\" >> ~/.profile"]
  }
```
 - db:
 - Разрешено подключение к монго со всех адресов
```
 provisioner "remote-exec" {
    inline = [
      "sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf",
      "sudo systemctl restart mongod"
    ]
  }
``` 

# Выполнено задание №6

 - Ветка terraform-1
 - Установлен terraform:
```
brew install terraform
```
 - Перенесны скрипт для диплоя Монолита и puma.service в папку files/
 - Созданы файлы: 

   1. main.tf - основной файл, описывающий параметры создаваемых инстансов,  
   2. variables.tf - входные переменные, 
   3. terrafirm.tfvars - определение переменных, 
   4. outputs.tf - выходные переменные

 - В .gitignore добавлены служебныйе файлы
 - Инициалализация:
```
terraform init
```
 - Просмотр изменений:
```
terraform plan
```
 - Выполнить создание инстансов:
```
terraform apply
```
 - Посмотреть внешний адрес созданного инстанса:
```
terraform show | grep nat_ip
```
 # Самостоятельное задание
 
- В terraform.tfvars добален путь до private key appuser - private_key_path 
 - В variables.tf добавлен:
```
variable private_key_path {
  description = "Path to the private key used for ssh conection"
}
```
 - В main.tf в блок connection добавлен: 
``` 
private_key = file(var.private_key_path)
```
- В terraform.tfvars добаленa зона для ресурса "google_compute_instance" "app"
 - В variables.tf добавлен:
```
variable zone {
  description = "Zone"
  # Значение по умолчанию
  default = "europe-west1-b"
}
```
 - В main.tf в блок resource добавлен:
```
zone = var.zone
```
 - Форматирование конфигов:
```
terraform fmt
```
 - Добавлен файл terraform.tfvars.example 

# Задание со *

 - Добавлен ключ пользователя appuser1:
```
resource "google_compute_project_metadata_item" "ssh-keys" {
  key = "ssh-key"
  value = "appuser1:${file(var.public_key_path)}
}
``` 
 - Добавлены ключи для appuser1, appuser2:
```
resource "google_compute_project_metadata_item" "ssh-keys" {
  key = "ssh-key"
  value = "appuser:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path1)}\nappuser2:${file(var.public_key_path2)}"
}
```
 - так же добавлены appuser1,appuser2 в метадату ресурса:
```
metadata = {
    # путь до публичного ключа
    ssh-keys = "appuser:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}\nappuser2:${file(var.public_key_path)}"
    block-project-ssh-keys = false
  }
```
 - При добавления руками в веинтерфейсе GCP ssh ключа пользователю appuser_web в метаданные проекта после terrsform apply удаляются

 # Задание с **

 - Создан lb.tf по документации https://www.terraform.io/docs/providers/google/r/compute_target_pool.html 
 - В outputs.tf добавлен балансировщик:
```
output "lb_external_ip" {
  value = google_compute_forwarding_rule.loadbalancer-firewall.ip_address
}
```
 - Добавлен ресурс reddit-app2 - такой подход с созданием доп. инстанса копированием кода выглядит нерационально, т.к. копируется много кода
 - Решение с добавление count в описание ресурса:
```
  count        = var.instances
  name         = "one-more-reddit-app${count.index}"
```
 - В variable.tf добалено:
```
variable instances {
  description = "Count of instances"
  default     = 1
}
```


 
# Выполнено задание №5

## В процессе сделано:
 - Ветка packer-base
 - Скрипты *.sh перенесены в папку config-scripts
 - Устновлен packer + авторизация ADC:
 ```
	gcloud auth application-default login
 ```
 - Добавлен ubuntu16.json в папку packer + перенесены *.sh скрипты = собран первоначальный образ
 - Добавлен variables.json = собран проект: 
 ``` 
	packer built -var-file variables.json ubuntu16.json
 ```
 или так:
 ```
	packer build -var 'project_id=some_id' \
		     -var 'source_image_family=ubuntu-1604-lts' \
		     -var 'machine_type=f1-micro'
 ``` 
 - Добавлен immutable.json, который создает образ семейства reddit-full + file/puma.service
 - Добавлен create-redditvm.sh, который поднимает инстанс семейства reddit-full

# Выполнено задание №4

## Впроцессе сделано:
 - Создана ветка cloud-testapp
 - Создана папка VPN, туда перемещены файлы из прошлого ДЗ:
   ```
	git mv setupvpn.sh cloud-bastion.ovpn VPN/
   ```  
 - Созданы файлы install_ruby.sh, install_mongobd.sh, deploy_sh c chmod +x
 - В панели GCP создано правило для порта 9292
 - Создан startup-cloud-testapp.sh
```
gcloud compute instances create new-reddit-app \
	--boot-disk-size=10GB \
	--image-family ubuntu-1604-lts \
	--image-project=ubuntu-os-cloud \
	--machine-type=g1-small \
	--tags puma-server \
	--restart-on-failure \
	--metadata-from-file startup-script=./startup-cloud-testapp.sh	

```
 - Правило firewall из консоли:
```
gcloud compute firewall-rules create default-puma-server \
	--network default \
	--action=ALLOW \
	--direction INGRESS \
	--target-tags puma-server \
	--source-ranges 0.0.0.0/0 \
	--rules tcp:9292 \
	--description "Allow incoming traffic on TCP port 9292 for tags puma-server"
```

testapp_IP = 35.241.181.119
testapp_port = 9292

# Выполнено ДЗ №3

## В процессе сделано:
 - В админпанели GCP cоздано 2 инстанса: 
	- bastion(internalIP:10.132.0.2, externalIP:35.205.111.103)
	- someinternalhost(internalIP:10.132.0.3) 
 - Создана пара ssh-ключей appuser (ssh-keygen -t rsa -f ~/.ssh/appuser -C appuser -P "") с выгрузкой .pub в Метаданные GCP

##  Самостоятельное и дополнительное задание реализовано с помощью конфига .ssh/config такого вида:

```
Host bastion
    Hostname 35.205.111.103
    User appuser
    IdentityFile ~/.ssh/appuser
    UseKeychain yes

Host someinternalhost
    Hostname 10.132.0.3
    User appuser
    IdentityFile ~/.ssh/appuser
    UseKeychain yes
    ProxyCommand ssh bastion nc 10.132.0.3 %p

TCPKeepAlive yes
ServerAliveInterval 30
ServerAliveCountMax 2
```
 - Одной командой): ssh someinternalhost
 - Если без помощи конфига, то: ssh -t -i ~/.ssh/appuser -A appuser@35.205.111.103 ssh appuser@10.132.0.3

## Как запустить проект:
 - Pritunl доступен по адресу: https://35-205-111-103.sslip.io/
 - cloud-bastion.ovpn закинул в tunnelBlick - ssh someinternalhost доступен с локалки
 - Сгенированный LetsEncrypt серт добавлен в файл:
```
nano /usr/lib/pritunl/lib/python2.7/site-packages/pritunl/app.py 

app_server.server_name = '35-205-111-103.sslip.io'

    server_cert_path = '/etc/letsencrypt/live/35-205-111-103.sslip.io/cert.pem'
    server_key_path = '/etc/letsencrypt/live/35-205-111-103.sslip.io/privkey.pem'
```

## Как проверить работоспособность:
 - https://35-205-111-103.sslip.io/

## PR checklist
 - [ ] Выставил label с cloud-bastion

bastion_IP = 35.205.111.103
someinternalhost_IP = 10.132.0.3

