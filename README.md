# eugenesable_infra
eugenesable Infra repository

# Google Cloud Platform

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
 login: pritunl
 password: P0lymorphism
## PR checklist
 - [ ] Выставил label с cloud-bastion

bastion_IP = 35.205.111.103
someinternalhost_IP = 10.132.0.3
