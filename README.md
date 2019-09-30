# eugenesable_infra
eugenesable Infra repository

# Google Cloud Platform

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

