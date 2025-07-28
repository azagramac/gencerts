# 🐧 Linux Cert & SSH Toolkit 🛠️

> Una **herramienta todo en uno** para gestionar certificados, claves SSH y GPG en entornos Linux, con una interfaz gráfica de consola sencilla y amigable.  
> Perfecta para usuarios que quieren crear CAs, renovar certificados Let's Encrypt, manejar claves SSH y GPG sin complicaciones.

<img width="673" height="483" alt="image" src="https://github.com/user-attachments/assets/0fd689ea-876e-4a7c-8c76-20f20cbed069" />


---

## 🚀 Características

- 🏛️ Crear una Autoridad Certificadora (CA) autofirmada para uso local.  
- 🔐 Generar certificados firmados por la CA.  
- ℹ️ Mostrar información detallada de certificados.  
- 🔑 Gestión completa de claves SSH: creación, listado.  
- 🌐 Renovación automática y consulta de validez de certificados Let's Encrypt con el nombre de dominio.  
- 🛡️ Gestión avanzada de claves GPG: creación, listado y visualización de claves locales y del sistema.  
---

## 📋 Dependencias

El script utiliza las siguientes herramientas:

| Herramienta | Uso principal                              | Instalación en Debian/Ubuntu           | Instalación en Fedora                   |
|-------------|-------------------------------------------|--------------------------------------|---------------------------------------|
| `openssl`   | Crear certificados y CA                    | `sudo apt install openssl`           | `sudo dnf install openssl`             |
| `whiptail`  | Interfaz gráfica en consola                 | `sudo apt install whiptail`           | `sudo dnf install newt`                |
| `ssh-keygen`| Crear claves SSH                            | `sudo apt install openssh-client`    | `sudo dnf install openssh`             |
| `gpg`       | Gestión de claves GPG                       | `sudo apt install gnupg`              | `sudo dnf install gnupg2`              |
| `certbot`   | Renovar certificados Let's Encrypt         | `sudo apt install certbot`            | `sudo dnf install certbot`             |
| `xclip`     | Copiar claves SSH al portapapeles (opcional) | `sudo apt install xclip`              | `sudo dnf install xclip`               |

> ⚠️ El script detecta automáticamente si `whiptail` está instalado y puede ayudarte a instalarlo.

---

## 💻 Uso

1. Clona este repositorio o descarga el script:

   ```bash
   git clone https://github.com/tuusuario/linux-cert-ssh-toolkit.git
   cd linux-cert-ssh-toolkit
   ```

2. Dale permisos de ejecución:

   ```bash
   chmod +x genCert.sh
   ```

3. Ejecuta el script:

   ```bash
   ./genCert.sh
   ```

🗂️ Estructura de directorios
Por defecto, el script guarda todos los archivos en:
```bash
/home/$USER/.gencerts/
├── ca/         # Certificados y claves CA
├── certs/      # Certificados firmados
├── ssh/        # Claves SSH generadas
├── gpg/        # Claves públicas GPG exportadas
├── letsencrypt/ # Certificados Let's Encrypt
├── logs/       # Archivos de log
└── config/     # Archivos de configuración
```

📄 Registro y configuración
Los logs se guardan en /home/$USER/.gencerts/logs/cert_ssh_toolkit.log.

La configuración se guarda en ```/home/$USER/.gencerts/config/cert_ssh_toolkit.conf``` para mantener todo centralizado.

⚖️ Licencia
GNU General Public License v3 © 2025 Jose l. Azagra

