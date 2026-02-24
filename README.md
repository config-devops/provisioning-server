# Provisioning Server

Script ini ngapain aja? :

✅ Auto detect: coba SSH key dulu
✅ Kalau gagal → fallback ke password
✅ Fix SSH rule config
✅ Create user devops kalau belum ada
✅ Setup sudoers NOPASSWD untuk devops
✅ Inject authorized_keys dengan pubkey yang di input
✅ Validate sshd config sebelum restart
✅ set date ke WIB
✅ Proper quoting (tidak kena bug sshpass)
✅ Idempotent (rerun aman)

sebelum jalanin bikin list server nya dulu :

``` bash
nano servers.txt
```
Contoh :
``` bash
1.1.1.1
2.2.2.2
3.3.3.3
```
langsung run :
``` bash

curl -O https://raw.githubusercontent.com/config-devops/provisioning-server/refs/heads/main/provisioning.sh

chmod +x provisioning.sh

./provisioning.sh
```
