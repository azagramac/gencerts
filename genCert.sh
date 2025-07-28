#!/bin/bash

#
# Script para gestionar certificados, claves SSH y GPG en Linux
# Developer: Jose l. Azagra
# Version: 1.0.0
# License: GPLv3
# Requisitos: openssl, whiptail, gpg, ssh-keygen, certbot
# Date: 29/07/2025
#

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="$SCRIPT_DIR/.cert_ssh_toolkit.conf"
LOG_FILE="$SCRIPT_DIR/.cert_ssh_toolkit.log"

# Directorios para certificados, claves, etc.
BASE_DIR="$SCRIPT_DIR/gencerts"
CA_DIR="$BASE_DIR/ca"
CERTS_DIR="$BASE_DIR/certs"
SSH_DIR="$BASE_DIR/ssh"
GPG_DIR="$BASE_DIR/gpg"
LETS_DIR="$BASE_DIR/letsencrypt"

# Crear directorios si no existen
mkdir -p "$CA_DIR" "$CERTS_DIR" "$SSH_DIR" "$GPG_DIR" "$LETS_DIR"

# Colores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Emojis
EMOJI_CA="🏛️"
EMOJI_CERT="🔐"
EMOJI_INFO="ℹ️"
EMOJI_SSH="🔑"
EMOJI_LETS="🌐"
EMOJI_GPG="🗝️"
EMOJI_EXIT="🚪"

log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

check_whiptail() {
  if ! command -v whiptail &>/dev/null; then
    echo -e "${YELLOW}[!] whiptail no está instalado. Algunas funciones requieren whiptail.${RESET}"
    read -p "¿Deseas instalarlo ahora? [s/N]: " respuesta
    if [[ "$respuesta" =~ ^[sS]$ ]]; then
      echo -e "\033]11;#FF0000\007"
      if [[ -f /etc/debian_version ]]; then
        sudo apt update && sudo apt install -y whiptail
      elif [[ -f /etc/fedora-release ]]; then
        sudo dnf install -y newt
      else
        echo -e "${RED}Sistema no compatible para instalación automática.${RESET}"
        exit 1
      fi
      echo -e "\033]11;#000000\007"
    else
      echo -e "${RED}No se instalará whiptail. Cancelando operación.${RESET}"
      return 1
    fi
  fi
}

crear_ca() {
  check_whiptail || return 1
  CA_KEY="$CA_DIR/ca.key"
  CA_PEM="$CA_DIR/ca.pem"

  DAYS=$(whiptail --title "Crear CA autofirmada" --inputbox "¿Días de validez de la CA?" 8 50 3650 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  CN=$(whiptail --title "Crear CA autofirmada" --inputbox "Nombre común (CN) para la CA:" 8 50 "MiCA" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  echo -e "\n${GREEN}>> Creando CA autofirmada...${RESET}"
  openssl genpkey -algorithm RSA -out "$CA_KEY" -pkeyopt rsa_keygen_bits:4096
  openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days "$DAYS" -out "$CA_PEM" -subj "/C=ES/ST=Madrid/L=Madrid/O=MiEmpresa/CN=$CN"

  VALIDEZ=$(openssl x509 -enddate -noout -in "$CA_PEM" | cut -d= -f2)
  whiptail --title "CA creada" --msgbox "CA creada correctamente.\n\nValidez hasta: $VALIDEZ\nRuta CA: $CA_PEM" 10 60
  log "CA autofirmada creada, válida hasta $VALIDEZ en $CA_PEM"
}

crear_cert() {
  check_whiptail || return 1
  CERT_KEY=""
  CERT_CSR=""
  CERT_CRT=""

  DOMAIN=$(whiptail --title "Crear certificado" --inputbox "Introduce el nombre del dominio:" 8 50 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  DAYS=$(whiptail --title "Crear certificado" --inputbox "¿Días de validez del certificado?" 8 50 825 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  CA_KEY="$CA_DIR/ca.key"
  CA_PEM="$CA_DIR/ca.pem"
  if [[ ! -f "$CA_KEY" || ! -f "$CA_PEM" ]]; then
    whiptail --title "Error" --msgbox "No se encontró la CA en $CA_DIR. Crea la CA primero." 8 50
    return
  fi

  CERT_KEY="$CERTS_DIR/$DOMAIN.key"
  CERT_CSR="$CERTS_DIR/$DOMAIN.csr"
  CERT_CRT="$CERTS_DIR/$DOMAIN.crt"

  openssl genpkey -algorithm RSA -out "$CERT_KEY" -pkeyopt rsa_keygen_bits:2048
  openssl req -new -key "$CERT_KEY" -out "$CERT_CSR" -subj "/C=ES/ST=Madrid/L=Madrid/O=MiEmpresa/CN=$DOMAIN"
  openssl x509 -req -in "$CERT_CSR" -CA "$CA_PEM" -CAkey "$CA_KEY" -CAcreateserial -out "$CERT_CRT" -days "$DAYS" -sha256

  VALIDEZ=$(openssl x509 -enddate -noout -in "$CERT_CRT" | cut -d= -f2)
  whiptail --title "Certificado creado" --msgbox "Certificado creado y firmado por la CA.\n\nValidez hasta: $VALIDEZ\nRuta certificado: $CERT_CRT" 10 60
  log "Certificado $DOMAIN creado, válido hasta $VALIDEZ en $CERT_CRT"
}

mostrar_info_cert() {
  check_whiptail || return 1

  # Buscar certificados en certs
  certs=("$CERTS_DIR"/*.crt)
  if [ ${#certs[@]} -eq 0 ] || [ ! -e "${certs[0]}" ]; then
    certs=()
  fi

  opciones=()
  for c in "${certs[@]}"; do
    basec=$(basename "$c")
    opciones+=("$c" "$basec")
  done

  if [ ${#opciones[@]} -eq 0 ]; then
    # No hay certificados
    certpath=$(whiptail --title "Mostrar info certificado" --inputbox "No se encontraron certificados.\nIntroduce ruta completa al certificado (.crt):" 10 70 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return
  else
    certpath=$(whiptail --title "Mostrar info certificado" --menu "Selecciona certificado para mostrar info:" 15 70 6 "${opciones[@]}" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && return
  fi

  if [[ -f "$certpath" ]]; then
    info=$(openssl x509 -in "$certpath" -noout -text)
    whiptail --title "Info certificado" --msgbox "$info" 25 90
  else
    whiptail --title "Error" --msgbox "No se encontró el archivo $certpath" 8 50
  fi
}

listar_archivos_en_menu() {
  # Parámetros: $1 = título, $2 = directorio, $3 = extensión (ejemplo: .pub)
  check_whiptail || return 1
  dir="$2"
  ext="$3"

  if [ ! -d "$dir" ]; then
    whiptail --title "Error" --msgbox "No existe el directorio $dir" 8 50
    return
  fi

  files=()
  while IFS= read -r -d '' f; do
    files+=("$f" "$(basename "$f")")
  done < <(find "$dir" -maxdepth 1 -type f -name "*$ext" -print0)

  if [ ${#files[@]} -eq 0 ]; then
    whiptail --title "Sin archivos" --msgbox "No se encontraron archivos $ext en $dir" 8 50
    return
  fi

  selected=$(whiptail --title "$1" --menu "Selecciona un archivo:" 20 70 10 "${files[@]}" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  contenido=$(cat "$selected")
  whiptail --title "Contenido de $(basename "$selected")" --msgbox "$contenido" 20 70
}

gestion_ssh() {
  check_whiptail || return 1
  while true; do
    opcion=$(whiptail --title "Gestión de claves SSH" --menu "Selecciona opción:" 15 60 6 \
      "1" "Crear nueva clave SSH" \
      "2" "Listar claves públicas SSH existentes" \
      "3" "Mostrar contenido de clave pública SSH" \
      "4" "Volver" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && break

    case $opcion in
      1)
        key_name=$(whiptail --title "Crear clave SSH" --inputbox "Nombre archivo para clave (sin extensión):" 8 50 "id_rsa" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue
        key_path="$SSH_DIR/$key_name"
        algo=$(whiptail --title "Algoritmo SSH" --menu "Selecciona algoritmo:" 15 50 3 \
          "rsa" "RSA (4096 bits)" \
          "ed25519" "Ed25519" \
          "ecdsa" "ECDSA" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue

        if [[ "$algo" == "rsa" ]]; then
          ssh-keygen -t rsa -b 4096 -f "$key_path"
        elif [[ "$algo" == "ed25519" ]]; then
          ssh-keygen -t ed25519 -f "$key_path"
        elif [[ "$algo" == "ecdsa" ]]; then
          ssh-keygen -t ecdsa -f "$key_path"
        fi
        log "Clave SSH generada en $key_path"
        whiptail --title "Clave SSH creada" --msgbox "Clave SSH creada en:\n$key_path" 8 60
        ;;
      2)
        listar_archivos_en_menu "Claves públicas SSH" "$SSH_DIR" ".pub"
        ;;
      3)
        pubkey=$(whiptail --title "Mostrar clave pública SSH" --inputbox "Ruta clave pública (.pub):" 8 60 "$SSH_DIR/id_rsa.pub" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue
        if [[ -f "$pubkey" ]]; then
          contenido=$(cat "$pubkey")
          whiptail --title "Contenido $pubkey" --msgbox "$contenido" 20 70
        else
          whiptail --title "Error" --msgbox "No se encontró el archivo $pubkey" 8 50
        fi
        ;;
      4) break ;;
      *) whiptail --msgbox "Opción inválida" 8 40 ;;
    esac
  done
}

gestion_gpg() {
  check_whiptail || return 1
  while true; do
    opcion=$(whiptail --title "Gestión de claves GPG" --menu "Selecciona opción:" 20 70 8 \
      "1" "Crear nueva clave GPG" \
      "2" "Listar claves públicas GPG locales" \
      "3" "Listar claves públicas GPG sistema" \
      "4" "Mostrar contenido de clave pública GPG local" \
      "5" "Mostrar info clave GPG sistema" \
      "6" "Volver" 3>&1 1>&2 2>&3)
    [ $? -ne 0 ] && break

    case $opcion in
      1)
        gpg --full-generate-key
        log "Clave GPG creada"
        whiptail --msgbox "Clave GPG creada." 8 40
        ;;
      2)
        # Listar claves locales (.asc)
        local_files=()
        while IFS= read -r -d '' f; do
          local_files+=("$f" "$(basename "$f")")
        done < <(find "$GPG_DIR" -maxdepth 1 -type f -name "*.asc" -print0)

        if [ ${#local_files[@]} -eq 0 ]; then
          whiptail --msgbox "No hay claves GPG locales en $GPG_DIR" 8 50
          continue
        fi

        sel_key=$(whiptail --title "Claves GPG locales" --menu "Selecciona una clave para ver su contenido:" 20 70 10 "${local_files[@]}" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue

        contenido=$(cat "$sel_key")
        whiptail --title "Contenido $(basename "$sel_key")" --msgbox "$contenido" 20 70
        ;;
      3)
        # Listar claves sistema (KEYID + uid)
        mapfile -t system_keys < <(gpg --list-keys --with-colons | awk -F: '/^pub/ {print $5}')
        if [ ${#system_keys[@]} -eq 0 ]; then
          whiptail --msgbox "No hay claves GPG en el sistema." 8 50
          continue
        fi

        menu_items=()
        for keyid in "${system_keys[@]}"; do
          name=$(gpg --list-keys --with-colons "$keyid" | awk -F: '/^uid/ {print $10; exit}')
          menu_items+=("$keyid" "$name")
        done

        sel_key=$(whiptail --title "Claves GPG sistema" --menu "Selecciona una clave para mostrar info:" 20 70 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue

        info=$(gpg --list-keys --with-fingerprint "$sel_key")
        whiptail --title "Info clave GPG $sel_key" --msgbox "$info" 20 70
        ;;
      4)
        pubkey=$(whiptail --title "Mostrar clave pública GPG" --inputbox "Ruta clave pública (.asc):" 8 60 "" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue
        if [[ -f "$pubkey" ]]; then
          contenido=$(cat "$pubkey")
          whiptail --title "Contenido $pubkey" --msgbox "$contenido" 20 70
        else
          whiptail --title "Error" --msgbox "No se encontró el archivo $pubkey" 8 50
        fi
        ;;
      5)
        keyid=$(whiptail --title "Mostrar info clave GPG sistema" --inputbox "Introduce ID o email de la clave:" 8 60 "" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue
        info=$(gpg --list-keys --with-fingerprint "$keyid" 2>&1)
        if [[ $info == *"no valid OpenPGP data found"* || $info == *"error"* ]]; then
          whiptail --title "Error" --msgbox "Clave no encontrada o inválida." 8 50
        else
          whiptail --title "Info clave GPG $keyid" --msgbox "$info" 20 70
        fi
        ;;
      6) break ;;
      *) whiptail --msgbox "Opción inválida" 8 40 ;;
    esac
  done
}

renovar_letsencrypt() {
  check_whiptail || return 1
  DOM=$(whiptail --title "Let's Encrypt" --inputbox "Dominio a renovar:" 8 50 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  MAIL=$(whiptail --title "Let's Encrypt" --inputbox "Correo de contacto:" 8 50 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  sudo certbot certonly --standalone -d "$DOM" --agree-tos -m "$MAIL" --non-interactive

  CERT_PATH="/etc/letsencrypt/live/$DOM/fullchain.pem"
  if [[ -f "$CERT_PATH" ]]; then
    VALIDEZ=$(openssl x509 -enddate -noout -in "$CERT_PATH" | cut -d= -f2)
    whiptail --title "Certificado Let's Encrypt" --msgbox "Certificado renovado.\nValidez hasta: $VALIDEZ" 10 60
    log "Let's Encrypt renovado para $DOM, válido hasta $VALIDEZ"
  else
    whiptail --title "Error" --msgbox "No se encontró el certificado generado para $DOM" 8 50
    log "Error: Certificado de Let's Encrypt para $DOM no encontrado tras la renovación"
  fi
}

consultar_validez_letsencrypt() {
  check_whiptail || return 1
  DOM=$(whiptail --title "Consultar validez Let's Encrypt" --inputbox "Introduce dominio:" 8 50 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  VALIDEZ=$(echo | openssl s_client -connect "$DOM:443" -servername "$DOM" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  if [ -z "$VALIDEZ" ]; then
    whiptail --title "Error" --msgbox "No se pudo obtener la validez para $DOM" 8 50
  else
    whiptail --title "Validez certificado $DOM" --msgbox "El certificado es válido hasta:\n$VALIDEZ" 10 50
  fi
}

mostrar_info_host() {
  HOSTNAME=$(hostname)
  OS=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
  KERNEL=$(uname -r)
  FECHA=$(date +"%Y-%m-%d %H:%M:%S")

  INFO="Host: $HOSTNAME\nSistema operativo: $OS\nKernel: $KERNEL\nFecha actual: $FECHA"
  whiptail --title "Información del host" --msgbox "$INFO" 10 50
}

mostrar_banner() {
  clear
  echo -e "${BLUE}"
  cat <<EOF
  ██████╗ ███████╗██████╗ ██╗███████╗███████╗
 ██╔═══██╗██╔════╝██╔══██╗██║██╔════╝██╔════╝
 ██║   ██║█████╗  ██████╔╝██║█████╗  █████╗  
 ██║   ██║██╔══╝  ██╔═══╝ ██║██╔══╝  ██╔══╝  
 ╚██████╔╝███████╗██║     ██║███████╗███████╗
  ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝╚══════╝

┌────────────────────────────────────────────┐
│        🐧  Linux Cert & SSH Toolkit 🐧       │
└────────────────────────────────────────────┘
EOF
  echo -e "${RESET}"
}

SCRIPT_VERSION="1.0.0"

menu_principal() {
  while true; do
    opcion=$(whiptail --title "🐧 Linux Cert & SSH Toolkit 🐧" --menu \
      "Selecciona opción:\n\nVersion $SCRIPT_VERSION" 20 70 10 \
      "1" "🏛️  Crear CA autofirmada" \
      "2" "🔐 Crear certificado firmado por CA" \
      "3" "ℹ️  Mostrar info de certificado" \
      "4" "🔑 Gestión de claves SSH" \
      "5" "🌐 Let's Encrypt (Renovar / Consultar)" \
      "6" "🛡️  Gestión de claves GPG" \
      "7" "💻 Mostrar info del host" \
      "8" "🚪 Salir" 3>&1 1>&2 2>&3)

    [ $? -ne 0 ] && break

    case $opcion in
      1) crear_ca ;;
      2) crear_cert ;;
      3) mostrar_info_cert ;;
      4) gestion_ssh ;;
      5)
        subopcion=$(whiptail --title "Let's Encrypt" --menu "Selecciona opción:" 15 70 6 \
          "1" "Renovar certificado" \
          "2" "Consultar validez certificado remoto" \
          "3" "Volver" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && continue
        case $subopcion in
          1) renovar_letsencrypt ;;
          2) consultar_validez_letsencrypt ;;
          3) continue ;;
        esac
        ;;
      6) gestion_gpg ;;
      7) mostrar_info_host ;;
      8) clear; echo "Adiós 👋"; exit 0 ;;
      *) whiptail --msgbox "Opción inválida" 8 40 ;;
    esac
  done
}


# Inicio
menu_principal

