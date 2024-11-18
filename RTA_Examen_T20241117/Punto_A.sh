#!/bin/bash
# Obtengo el path del disco de 1GB para particionarlo -
PATH_DISCO_PARTICIONAR1=$(lsblk | grep 1G | head -n 1 | awk '{print "/dev/"$1}')
echo "Particionando el disco de 1GB"
sudo fdisk $PATH_DISCO_PARTICIONAR1 << EOF
n
p
1
2048
+700M
w
EOF
echo "Partición creada correctamente aguarde por favor!"
echo "-------------------------------------------------------------------------------	-------------------------------------"

# Ahora obtengo el path del disco de 2GB para particionarlo
PATH_DISCO_PARTICIONAR2=$(lsblk | grep 2G | head -n 1 | awk '{print "/dev/"$1}')
echo "Particionando el disco de 2GB ESPERE !!"
sudo fdisk $PATH_DISCO_PARTICIONAR2 << EOF
n
p
1
2048
+1.530G
t
1
8e
w
EOF
echo "Partición creada correctamente :) Sigamos"
echo "--------------------------------------------------------------------------------------------------------------------"

# Configuración de LVM:
# Obtengo las rutas de las particiones recién creadas
PATH_PARTICION_TEMP="${PATH_DISCO_PARTICIONAR1}1"  # Partición de 700MB
PATH_PARTICION_DATOS="${PATH_DISCO_PARTICIONAR2}1" # Partición de 1.5GB

# Limpio las particiones para evitar restos de datos
sudo wipefs -a $PATH_PARTICION_DATOS $PATH_PARTICION_TEMP

# Creo los Physical Volumes (PVs) con las particiones disponibles
sudo pvcreate $PATH_PARTICION_DATOS $PATH_PARTICION_TEMP

# Creo los Volume Groups (VGs) necesarios
sudo vgcreate vg_temp $PATH_PARTICION_TEMP
sudo vgcreate vg_datos $PATH_PARTICION_DATOS

# A continuación, creo los Logical Volumes (LVs) en cada VG
# Nota: El mínimo que acepta son 8M para lv_docker, aunque especifique 5M
sudo lvcreate -L 5M -n lv_docker vg_datos
sudo lvcreate -L 1.5G -n lv_workareas vg_datos
sudo lvcreate -L 512M -n lv_swap vg_temp

# Configuro el área de intercambio (swap)
echo "----------------------------------------------------------------------------------------------------------------"
echo "Habilitando memoria swap"
PATH_LV_SWAP=$(sudo fdisk -l | grep swap | awk '{print $2}' | cut -d':' -f1)
sudo mkswap $PATH_LV_SWAP
sudo swapon $PATH_LV_SWAP
echo "Memoria swap habilitada correctamente"
free -h
echo "----------------------------------------------------------------------------------------------------------------"

# Creo la carpeta para el montaje del LV correspondiente en caso de que ya este creada, saltea
sudo mkdir /work/

# Obtengo las rutas de los Logical Volumes para montarlos
PATH_LV_DOCKER=$(sudo fdisk -l | grep lv_docker | awk '{print $2}' | cut -d':' -f1)
PATH_LV_WORKAREAS=$(sudo fdisk -l | grep workareas | awk '{print $2}' | cut -d':' -f1)

# Formateo los volúmenes lógicos del VG "vg_datos" con ext4
sudo mkfs.ext4 $PATH_LV_DOCKER
sudo mkfs.ext4 $PATH_LV_WORKAREAS

# Finalmente, monto los volúmenes en los directorios correspondientes
sudo mount $PATH_LV_DOCKER /var/lib/docker/
sudo mount $PATH_LV_WORKAREAS /work/

# Reinicio Docker para que use la nueva ubicación
sudo systemctl restart docker

