#!/bin/bash
# Hardening Script for HPCC Team 21

export t=21
BACKUP_DEST="plinktern@172.16.${t}.5:/home/plinktern/"

echo "🚀 Starting Hardening Procedure..."

# 1. LOCAL & OFFSITE BACKUPS
echo "📦 Creating local and offsite backups..."
tar -czvf /root/hpcc_backup.tar.gz /etc /var /home /etc/ssh
# Attempt to push to blackbox (ignoring failure if blackbox isn't up yet)
scp /root/hpcc_backup.tar.gz ${BACKUP_DEST} 2>/dev/null || echo "⚠️ Offsite backup to blackbox skipped/failed."

# 2. SSH HARDENING
echo "🔒 Hardening SSH configuration..."
passwd -l root 2>/dev/null
sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
sed -i '/^Protocol/d' /etc/ssh/sshd_config
sed -i '/^AllowUsers/d' /etc/ssh/sshd_config

echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
echo "AllowUsers jmoney plinktern" >> /etc/ssh/sshd_config

# Secure file permissions
chmod 644 /etc/passwd
systemctl restart sshd || systemctl restart ssh

# 3. USER MANAGEMENT & JMONEY STRIPPING
echo "👤 Updating critical passwords..."
echo -e "jmoney:NewSecurePasswordHere\nplinktern:NewSecurePasswordHere" | chpasswd

echo "🧹 Removing unnecessary local user accounts..."
for user in $(cut -d: -f1 /etc/passwd); do
  uid=$(id -u "$user" 2>/dev/null)
  if [[ "$uid" -ge 1000 && "$user" != "nobody" && "$user" != "jmoney" && "$user" != "plinktern" ]]; then
    echo "❌ Deleting unauthorized user: $user"
    userdel -r "$user" &>/dev/null
  fi
done

echo "🔧 Stripping privileges from jmoney..."
gpasswd -d jmoney wheel &>/dev/null
gpasswd -d jmoney sudo &>/dev/null
sed -i '/^jmoney/d' /etc/sudoers
rm -f /etc/sudoers.d/jmoney

# 4. FIREWALL SETUP (Differentiating APT vs DNF)
echo "🛡️ Configuring firewall..."
if command -v dnf &> /dev/null; then
    dnf install firewalld -y
    systemctl enable --now firewalld

    firewall-cmd --zone=public --add-service=ssh --permanent
    firewall-cmd --zone=public --add-service=http --permanent
    # firewall-cmd --permanent --zone=public --set-target=DROP
    firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" port port="4444" protocol="tcp" reject' --permanent
    firewall-cmd --reload
elif command -v apt &> /dev/null; then
    apt update && apt install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw --force enable
fi

# 5. INSTALL UTILITIES & MONITORING TOOLS
echo "📥 Installing security and monitoring tools..."
if command -v dnf &> /dev/null; then
    dnf install -y htop ranger tmux curl whowatch fail2ban
elif command -v apt &> /dev/null; then
    apt install -y htop ranger tmux curl whowatch fail2ban
fi

# Install pspy64 for process monitoring
curl -L -o /usr/local/bin/pspy64 https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64
chmod +x /usr/local/bin/pspy64

history -c

echo "✅ Hardening script completed successfully!"
echo "⚠️ NOTE: Run 'chattr +i' manually on critical files ONLY after you are completely done making changes!"