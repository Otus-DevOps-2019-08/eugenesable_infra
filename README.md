# eugenesable_infra
eugenesable Infra repository

# Google Cloud Platform

# Выполнено задание №10

 - Ветка ansible-3
 - Добавлено Динамик Инвентори из прошлого ДЗ: очень удобно)
 https://docs.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html#examples
 ```
---
plugin: gcp_compute
projects:
  - infra-******
service_account_file: ~/keys/infra.json
auth_kind: serviceaccount
hostnames:
  - name
groups:
  app: "'-app' in name"
  db: "'-db' in name"
compose:
  ansible_host: networkInterfaces[0].accessConfigs[0].natIP
  internal_ip: networkInterfaces[0].networkIP

 ```  
 - Изменили ansible.cfg - invetory.gcp.yml
 - Инициализированы роли app и db 
 ```ansible-galaxy init app``` 
 ```ansible-galaxy init db```
 - template, vars, handler и task перенесены в роль db и app соответственно
 - В плэйбуках app и db добвлены соответсвующие роли
 - Добавлены inventory для окружений stage и prod
 - Прод плэйбук теперь запускается так:``` ansible-playbook -i environments/prod/inventory deploy.yml```
 - В конфиге ansible.cfg добавлен конфиг окружения stage поумолчанию
 - Добавлены group_vars в каждое окружение, в которые выненсены переменные каждого прилажения
 - В роли добавлена переменная - окружение поумолчанию - env:local
 - Добавлен вывод информации об окружении в таски с помощью модуля debug:
 ```
 - name: Show info about the env this host belongs to
   debug:
     msg: "This host is in {{ env }} environment!!!"
 ```    
 - Реорганизована директория ansible/
 - Изменен конфиг ansible.cfg:
 ```
 [defaults]
inventory = ./environments/stage/inventory.gcp.yml
remote_user = appuser
private_key_file = ~/.ssh/appuser
# Отключим проверку SSH Host-keys (поскольку они всегда разные для новых инстансов)
host_key_checking = False
# Отключим создание *.retry-файлов (они нечасто нужны, но мешаются под руками)
retry_files_enabled = False
# # Явно укажем расположение ролей (можно задать несколько путей через ; )
roles_path = ./roles
[diff]
# Включим обязательный вывод diff при наличии изменений и вывод 5 строк контекста
always = True
context = 5
```
 - Собрано тестовое окуржение:
 ```
 TASK [db : Show info about the env this host belongs to] ***********************************************************************
 ok: [reddit-db] => {
    "msg": "This host is in stage environment!!!"
 }
 TASK [app : Show info about the env this host belongs to] **********************************************************************
 ok: [reddit-app] => {
    "msg": "This host is in stage environment!!!"
 }
 ```   
- Добавлена роль jdauphant.nginx:
 ```ansible-galaxy install -r environments/stage/requirements.yml``` 
- Настроено обратное проксирование в stage/group_vars/app и prod/group_vars/app:
```
nginx_sites:
  default:
    - listen 80
    - server_name "reddit"
    - location / {
        proxy_pass http://127.0.0.1:9292;
      }
```
- Добавлено правило ФВ в террафорсе для 80 порта:
```
resource "google_compute_firewall" "firewall_http" {
  name    = "allow-http-default"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}
``` 
- В плэйбук app.yml добавлена роль jdauphant.nginx
- Добавлены настройки пользователей credentials.yml в обоих окружениях
- Добавлен плэйбук для создания пользователей:
```

---
- name: Create users
  hosts: all
  become: true

  vars_files:
    - "{{ inventory_dir }}/credentials.yml"

  tasks:
    - name: create users
      user:
        name: "{{ item.key }}"
        password: "{{ item.value.password|password_hash('sha512', 65534|random(seed=inventory_hostname)|string) }}"
        groups: "{{ item.value.groups | default(omit) }}"
      with_dict: "{{ credentials.users }}"

```
- Зашифрованы настройки пользователей credentials.yml в обоих окружениях:
```ansible-vault encrypt environments/prod/credentials.yml```
```ansible-vault encrypt environments/stage/credentials.yml```
- Собран stage. Доступ по паролю не разрешен по умолчанию. Добавлена таска в app, которая изменяет конфиг sshd и хендлер, перезапускающий sshd:
```
- name: allow ssh by password
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PasswordAuthentication no'
    line: PasswordAuthentication yes
  notify: reload sshd
```
```
- name: reload sshd
  become: true
  systemd: name=sshd state=restarted
```
Задание со *:
- Выполнено  помощью gcp_compute. В окуржения добавлены inventory.gcp.yml
Задание с **
- че-то не понял пока...

# Выполнено задание №9

 - Ветка ansible-2
 - В модулях app и db закомментированы провижинеры и создано новое окружение
 - Добавлен плэйбук reddit_app.yml:
  
   ```
   ---
   - name: Con§igure hosts & deploy application
     hosts: all
     vars:
       mongo_bind_ip: 0.0.0.0
     tasks:
       - name: Change mongo config file
         become: true # <-- Выполнить задание от root
         template:
           src: templates/mongod.conf.j2 # <-- Путь до локального файла-шаблона
           dest: /etc/mongod.conf # <-- Путь на удаленном хосте
           mode: 0644 # <-- Права на файл, которые нужно установить
         tags: db-tag
         notify: restart mongo
     handlers: 
     - name: restart nongo
       become: true
       service: name=mongod state=restarted
   ```
- Добавлен шаблон mongod.conf.j2:
- Пробный заупск: ``` ansible-playbook reddit_app.yml --check --limit db``` 
- Добавлена переменная:
   ```
   vars:
       mongo_bind_ip: 0.0.0.0
   ```
- Добавлен Handler:
  ```
  handlers: 
  - name: restart nongo
    become: true
    service: name=mongod state=restarted
  ```
- Выполнение плэйбука: ```ansible-playbook reddit_app.yml --limit db```
- Добален task для puma.service и handler для DATABASE_URL:
```
- name: Add unit file for Puma
  become: true
  copy:
    src: files/puma.service
    dest: /etc/systemd/system/puma.service
  tags: app-tag
  notify: reload puma

- name: enable puma
  become: true
  systemd: name=puma enabled=yes
  tags: app-tag

handlers: 
- name: reload puma
  become: true
  systemd: name=puma state=restarted

```
- Добавлен task для деплоя и установки ruby gems:
```
- name: Fetch the latest version of application code
  git:
    repo: 'https://github.com/express42/reddit.git'
    dest: /home/appuser/reddit
    version: monolith # <-- Указываем нужную ветку
  tags: deploy-tag  
  notify: reload puma

- name: Bundle install
  bundler:
    state: present
    chdir: /home/appuser/reddit # <-- В какой директории выполнить команду bundle
  tags: deploy-tag
```
- Добавлен плэйбук reddit-app2.yml с 3-мя сценариями:
```
---
- name: Configure MongoDB
  hosts: db
  tags: db-tag
  become: true
  vars:
    mongo_bind_ip: 0.0.0.0
  tasks:
    - name: Change mongo config file
      template:
        src: templates/mongod.conf.j2
        dest: /etc/mongod.conf
        mode: 0644
      notify: restart mongod

  handlers:
  - name: restart mongod
    service: name=mongod state=restarted

- name: Configure App
  hosts: app
  tags: app-tag
  become: true
  vars:
   db_host: 10.132.0.5
  tasks:
    - name: Add unit file for Puma
      copy:
        src: files/puma.service
        dest: /etc/systemd/system/puma.service
      notify: reload puma

    - name: Add config for DB connection
      template:
        src: templates/db_config.j2
        dest: /home/appuser/db_config
        owner: appuser
        group: appuser

    - name: enable puma
      systemd: name=puma enabled=yes
  
  handlers:
  - name: reload puma
    become: true
    systemd: name=puma state=restarted      

- name: Deploy reddit-app
  hosts: app
  tags: deploy-tag
  become: true
  tasks:
    - name: Fetch the latest version of application code
      git:
        repo: 'https://github.com/express42/reddit.git'
        dest: /home/appuser/reddit
        version: monolith # <-- Указываем нужную ветку
      notify: reload puma
    
    - name: Bundle install
      bundler:
        state: present
        chdir: /home/appuser/reddit # <-- В какой директории выполнить команду bundle

  handlers:
  - name: restart puma
    become: true
    systemd: name=puma state=restarted

```
- Из предыдущего плэйбука сформировано 3 app.yml, db.yml, deploy.yml:
- Добавлен site.yml, который включает в себя все созданные ранее 3 плэйбука:
```
---
- import_playbook: db.yml
- import_playbook: app.yml
- import_playbook: deploy.yml
``` 
- МЕСТО ДЛЯ ЗАДАНИЯ СО* DYNAMIC INVENTORY
- Добавлены плэйбуки для провиженинга образов пакера:
  packer_app.yml:
  ```
  ---
- name: Ruby & Bundler
  hosts: all
  become: true
  tasks: 
    - name: Install ruby-full ruby-bundler build-essential
      apt:
        name: "{{ item }}"
        state: present
      with_items:
        - ruby-full
        - ruby-bundler
        - build-essential
  ```
   packer_db.yml:
  ```
  ---
- name: MongoDB
  hosts: all
  become: true
  vars: 
    key_id: D68FA50FEA312927
  tasks:
    - name: Add apt-key, mongo repo and update
      apt_key:
        keyserver: keyserver.ubuntu.com
        id: "{{ key_id }}"
    - name: Repo
      apt_repository:
        repo: deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse
        state: present
    - name: Update     
      apt:
        update_cache: yes
    - name: Install mongo
      apt:
        name: mongodb-org
        state: present 
    - name: Mongo service
      systemd: 
        name: mongod
        state: started
        enabled: yes

  ``` 
- Изменены провиженеры с shell на ansible:
  app.json:
  ```
  "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_app.yml"
        }
  ]
  ```
  db.json:
  ```
  "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/packer_db.yml"
        }
  ]
  ```
  -  Собрано окружение с новыми образами
    
# Выполнено задание №8

 - Ветка ansible-1
 - Установлен Ansible ```pip install -r requirements.txt```
 - Поднята stage инфраструктура
 - Создан inventory ```appserver ansible_host=34.77.168.130 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser```
 - Проверена работоспособность с помощью модуля ping ```ansible appserver -i ./inventory -m ping```
 - Добавлен хост dbserver: ```dbserver ansible_host=35.187.124.237 ansible_user=appuser ansible_private_key_file=~/.ssh/appuser```
 - Добавлен ansible.cfg: 
 ```
 [defaults]
 inventory = ./inventory
 remote_user = appuser
 private_key_file = ~/.ssh/appuser
 host_key_checking = False
 retry_files_enabled = False
 ```
 - inventory приведен к виду:
 ```
 [app]
 appserver ansible_host=34.77.168.130
 [db]
 dbserver ansible_host=35.187.124.237
 ``` 
 - Добавлен inventory.yml:
 ```
 ---
 app:
   hosts:
     appserver:
       ansible_host: 34.77.168.130

 db:
   hosts:
     dbserver:
       ansible_host: 35.187.124.237
 ```
 - Переопределили инвентори файл с помощью -i: ```ansible all -m ping -i inventory.yml```
 - Проверили выполнение команд:
   ```ansible app -m command -a 'ruby -v'``` - Версия ruby на группе хостов app с помощью модуля command
   ```ansible app -m shell -a 'ruby -v; bundler -v'``` - Версия ruby и bundle на группе хостов app с помощью модуля shell
   ```ansible db -m command -a 'systemctl status mongod'``` - Статус монго с помощью модуля command
   ```ansible db -m systemd -a name=mongod``` - Статус монго с помощью модуля systemd
   ```ansible db -m service -a name=mongod``` - Статус монго с помощью модуля service
   ```ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'``` - Клонирование с помощью модуля git
 - Добавлен плейбук clone.yml:
 ```
 ---
 - name: Clone
   hosts: app
   tasks:
     - name: Clone repo
       git:
         repo: https://github.com/express42/reddit.git
         dest: /home/appuser/reddit
```     
 - Запуск плэйбука: ```ansible-playbook clone.yml```
 - Добавлен статичский inventory.json:
 ```
 {
    "app": {
        "hosts": ["34.77.168.130"]
    },
    "db": {
        "hosts": ["35.187.124.237"]
    }
}
```
- В интернетах найден скрипт для создания динмическогоg инвентори: https://gist.github.com/sivel/3c0745243787b9899486
```
import sys
import json

from ansible.parsing.dataloader import DataLoader

try:
    from ansible.inventory.manager import InventoryManager
    A24 = True
except ImportError:
    from ansible.vars import VariableManager
    from ansible.inventory import Inventory
    A24 = False

loader = DataLoader()
if A24:
    inventory = InventoryManager(loader, [sys.argv[1]])
    inventory.parse_sources()
else:
    variable_manager = VariableManager()
    inventory = Inventory(loader, variable_manager, sys.argv[1])
    inventory.parse_inventory(inventory.host_list)

out = {'_meta': {'hostvars': {}}}
for group in inventory.groups.values():
    out[group.name] = {
        'hosts': [h.name for h in group.hosts],
        'vars': group.vars,
        'children': [c.name for c in group.child_groups]
    }
for host in inventory.get_hosts():
    out['_meta']['hostvars'][host.name] = host.vars

print(json.dumps(out, indent=4, sort_keys=True))
```
- Запуск ```python inventory2json.py inventory``` - вынесено в inventory.sh
- Изменен ansible.cfg:
```
[defaults]
inventory = ./inventory.sh
remote_user = appuser
private_key_file = ~/.ssh/appuser
host_key_checking = False
retry_files_enabled = False
```


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
  description = "Private key path"
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
 - При добавления руками в вебинтерфейсе GCP ssh ключа пользователю appuser_web в метаданные проекта после terraform apply удаляются

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

