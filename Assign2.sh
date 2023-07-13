#!/bin/bash

# Function to display status messages
 display_message() {
  echo "==============================="
  echo "$1"
  echo "==============================="
  echo
}

# Function to display error messages and exit
 display_error() {
  echo "Error: $1"
  exit 1
}

# Now, to check if the script is running with root privileges
if [ "$(id -u)" -ne 0 ]; then
  display_error "This script must be run as root."
fi

# TO Updatethe hostname
display_message "Updating hostname"
hostnamectl set-hostname autosrv || display_error "Failed to update hostname"

# Update network configuration
display_message "Updating network configuration"
network_file="/etc/netplan/01-netcfg.yaml"
network_config=$(cat <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens34:
      dhcp4: no
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF
)
echo "$network_config" > "$network_file" || display_error "Failed to update network configuration"
netplan apply || display_error "Failed to apply network configuration"

# Software Installation
display_message "Installing required software"
if ! apt update; then
  display_error "Failed to update package repositories"
fi

if ! apt install -y openssh-server apache2 squid ufw; then
  display_error "Failed to install software"
fi

# Configuration of SSH server
display_message "Configuring SSH server"
ssh_config="/etc/ssh/sshd_config"
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$ssh_config" || display_error "Failed to update PasswordAuthentication setting"
systemctl restart ssh || display_error "Failed to restart SSH server"


# Configuration of Apache web server
display_message "Configuring Apache web server"
sed -i 's/Listen 80/Listen 0.0.0.0:80/' /etc/apache2/ports.conf || display_error "Failed to configure Apache ports"
a2dissite 000-default || display_error "Failed to disable default Apache site"
a2enmod ssl || display_error "Failed to enable Apache SSL module"
a2ensite default-ssl || display_error "Failed to enable Apache SSL site"
systemctl restart apache2 || display_error "Failed to restart Apache web server"

# Configuration of Squid web proxy
display_message "Configuring Squid web proxy"
sed -i 's/http_port 3128/http_port 0.0.0.0:3128/' /etc/squid/squid.conf || display_error "Failed to configure Squid port"
systemctl restart squid || display_error "Failed to restart Squid web proxy"

# Configuration of firewall with UFW
display_message "Configuring firewall with UFW"
ufw allow 22/tcp || display_error "Failed to allow SSH"
ufw allow 80/tcp || display_error "Failed to allow HTTP"
ufw allow 443/tcp || display_error "Failed to allow HTTPS"
ufw allow 3128/tcp || display_error "Failed to allow Squid proxy"
ufw enable || display_error "Failed to enable UFW"

# Creating user accounts
display_message "Creating user accounts"
user_list=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${user_list[@]}"; do
  useradd -m -s /bin/bash "$user" || display_error "Failed to create user $user"
  mkdir -p "/home/$user/.ssh" || display_error "Failed to create .ssh directory for user $user"
  ssh-keygen -q -t rsa -N "" -f "/home/$user/.ssh/id_rsa" || display_error "Failed to generate RSA key for user $user"
  ssh-keygen -q -t ed25519 -N "" -f "/home/$user/.ssh/id_ed25519" || display_error "Failed to generate Ed25519 key for user $user"
  cat "/home/$user/.ssh/id_rsa.pub" >> "/home/$user/.ssh/authorized_keys" || display_error "Failed to add RSA public key for user $user"
  cat "/home/$user/.ssh/id_ed25519.pub" >> "/home/$user/.ssh/authorized_keys" || display_error "Failed to add Ed25519 public key for user $user"
  chown -R "$user:$user" "/home/$user/.ssh" || display_error "Failed to set ownership for .ssh directory of user $user"
done

# Configuring the sudo access for dennis
display_message "Configuring sudo access for dennis"
echo "dennis ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/dennis || display_error "Failed to configure sudo access for dennis"

display_message "System configuration complete"
