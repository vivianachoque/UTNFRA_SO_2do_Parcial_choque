#!/bin/bash


# Verificamos si se proporcionaron los dos parámetros necesarios
if [ $# -ne 2 ]; then
  echo "Uso: $0 <usuario_admin> <archivo_lista_usuarios>"
  exit 1
fi

# Asignamos los parámetros a variables
usuario_admin="$1"
archivo_lista_usuarios="$2"

# Función para crear un grupo
crear_grupo() {
  groupadd "$1"
}

# Función para crear un usuario y asignarlo al grupo
crear_usuario() {
  useradd "$1" -p $(grep "$usuario_admin" /etc/shadow | cut -d: -f2)
  usermod -aG "$1" "$1"
}

# Obtenemos la contraseña del usuario administrador
contrasena_admin=$(grep "$usuario_admin" /etc/shadow | cut -d: -f2)

# Leemos la lista de usuarios del archivo
while IFS= read -r usuario; do
  # Creamos el grupo con el mismo nombre que el usuario
  crear_grupo "$usuario"
  # Creamos el usuario y lo agregamos al grupo
  crear_usuario "$usuario"
done < "$archivo_lista_usuarios"

echo "Usuarios y grupos creados correctamente."
