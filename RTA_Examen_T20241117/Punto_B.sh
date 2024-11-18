#!/bin/bash

# Verificar si se recibió el parámetro del usuario
if [ $# -ne 1 ]; then
    echo "Uso: $0 <usuario>"
    exit 1
fi

# Variables
USUARIO_REFERENCIA=$1
ARCHIVO_USUARIOS="/home/osboxes/Desktop/UTN-FRA_SO_Examenes/202406/bash_script/Lista_Usuarios.txt"

# Verificar si existe el usuario de referencia
if ! id "$USUARIO_REFERENCIA" &>/dev/null; then
    echo "Error: El usuario de referencia $USUARIO_REFERENCIA no existe"
    exit 1
fi

# Obtener la clave del usuario de referencia
CLAVE_REFERENCIA=$(grep "^$USUARIO_REFERENCIA:" /etc/shadow | cut -d: -f2)

# Verificar si existe el archivo de usuarios
if [ ! -f "$ARCHIVO_USUARIOS" ]; then
    echo "Error: No se encuentra el archivo de usuarios en $ARCHIVO_USUARIOS"
    exit 1
fi

# Leer el archivo de usuarios y crear grupos y usuarios
while IFS=',' read -r usuario grupo directorio || [ -n "$usuario" ]; do
    # Ignorar líneas vacías o comentarios
    [[ -z "$usuario" || "$usuario" =~ ^[[:space:]]*# ]] && continue
    
    # Limpiar posibles espacios en blanco
    usuario=$(echo "$usuario" | tr -d ' ')
    grupo=$(echo "$grupo" | tr -d ' ')
    directorio=$(echo "$directorio" | tr -d ' ')
    
    # Crear el grupo si no existe
    if ! getent group "$grupo" &>/dev/null; then
        groupadd "$grupo"
        echo "Grupo creado: $grupo"
    fi
    
    # Crear el usuario si no existe
    if ! id "$usuario" &>/dev/null; then
        # Crear el directorio base si no existe
        if [ ! -d "$directorio" ]; then
            mkdir -p "$directorio"
        fi
        
        # Crear usuario con directorio home específico y grupo primario
        useradd -m -d "$directorio" -g "$grupo" "$usuario"
        
        # Establecer la misma contraseña que el usuario de referencia
        usermod -p "$CLAVE_REFERENCIA" "$usuario"
        
        # Ajustar permisos del directorio
        chown -R "$usuario":"$grupo" "$directorio"
        
        echo "Usuario creado: $usuario"
        echo "  - Grupo primario: $grupo"
        echo "  - Directorio home: $directorio"
    fi
done < "$ARCHIVO_USUARIOS"

echo "Proceso completado exitosamente"
