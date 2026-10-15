#!/bin/bash
# @ftbento
# Hardening for HPCC
# sudo ./linux.sh

export t=21
export pass=nerves-alight-beeper

echo "Installs:"
if command -v dnf &> /dev/null; then
    dnf install -y htop tmux curl whowatch fail2ban firewalld ipset
elif command -v apt &> /dev/null; then
    apt update
    apt install -y htop tmux curl whowatch fail2ban ufw
fi

# pspy64 for live process monitoring
if [ ! -x /usr/local/bin/pspy64 ]; then
  curl -fsSL -o /usr/local/bin/pspy64 \
    https://github.com/DominicBreuker/pspy/releases/latest/download/pspy64 && \
    chmod +x /usr/local/bin/pspy64 && echo "pspy64 installed" || echo "pspy64 download failed (no internet?)"
else
  echo "pspy already installed"
fi

echo "Hardening..."

echo "Local + blackbox backup"
tar -czvf /root/sys.tar.gz /etc /var /home /etc/ssh
scp /root/sys.tar.gz plinktern@172.16.${t}.5:/home/plinktern/ 2>/dev/null || echo "⚠️ Offsite backup to blackbox skipped/failed."
# scp plinktern@172.16.21.5:/home/plinktern/sys.tar.gz /root/
# cd /
# tar -xzvf /root/sys.tar.gz
# restart through systemctl, whatever
# check chmod file perms for system files

echo "Disabling root login"
passwd -l root 2>/dev/null # disable root login

# SSH
echo "SSH hardening"
sed -i '/^PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config

sed -i '/^Protocol/d' /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config

sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
echo "AllowUsers jmoney plinktern" >> /etc/ssh/sshd_config

# Secure file permissions
chmod 644 /etc/passwd
systemctl restart sshd || systemctl restart ssh

# User mgmt
echo "Updating user passwords..."
echo "REMEMBER TO UPDATE IN SCOREBOARD FOR JMONEY ACCOUNT TO ${pass}"
echo -e "jmoney:${pass}\nplinktern:${pass}" | chpasswd

echo "Removing unnecessary local user accounts..."
for user in $(cut -d: -f1 /etc/passwd); do
  uid=$(id -u "$user" 2>/dev/null)
  if [[ "$uid" -ge 1000 && "$user" != "nobody" && "$user" != "jmoney" && "$user" != "plinktern" ]]; then
    echo "❌ Deleting unauthorized user: $user"
    userdel -r "$user" &>/dev/null
  fi
done

echo "Stripping privileges from jmoney..."
gpasswd -d jmoney wheel &>/dev/null
gpasswd -d jmoney sudo &>/dev/null
sed -i '/^jmoney/d' /etc/sudoers
rm -f /etc/sudoers.d/jmoney

# FIREWALL
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
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw --force enable
fi

# FAIL2BAN
echo "Configuring fail2ban..."
# Ban with whichever firewall is already managing the box
if command -v firewall-cmd &> /dev/null; then
    BANACTION="firewallcmd-ipset"
elif command -v ufw &> /dev/null; then
    BANACTION="ufw"
else
    BANACTION="iptables-multiport" # should never happen hopefully
fi

# jail.d/*.local is parsed last, so this overrides distro defaults
cat > /etc/fail2ban/jail.d/99-hpcc.local <<EOF
[DEFAULT]
ignoreip  = 127.0.0.1/8 ::1
bantime   = 1h
findtime  = 10m
maxretry  = 5
banaction = ${BANACTION}

[sshd]
enabled = true
port    = ssh
mode    = normal
EOF

systemctl enable fail2ban &>/dev/null
systemctl restart fail2ban

sleep 1
echo "fail2ban status:"
fail2ban-client status 2>/dev/null
fail2ban-client status sshd 2>/dev/null

history -c

echo "✅ Hardening script completed successfully!"
echo "chattr +i /etc/ssh/sshd_config"
echo "chattr +i /etc/passwd"
echo "chattr +i /etc/shadow"
