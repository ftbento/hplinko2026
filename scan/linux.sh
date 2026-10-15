# general information read only quick runs (output to fill, diff comparison as competition goes on)
# sudo ./linux.sh > ~/scan/scan-$(date +%Y%m%d_%H%M%S).txt

mkdir -p ~/scan
echo "Scan  $(date)"
echo "host: $(hostname)"
echo
echo "------------- NETWORK -----------"
echo "Listening Ports"
ss -tulpna

echo "Established Connections"
ss -tnp state established

echo "ARP Cache"
ip neigh show # horse

echo "Routing Table"
ip route show

echo
echo "------------- USERS -----------"
echo "Accounts with login shells"
grep -Ev '(nologin|/false|/sync|/shutdown|/halt)$' /etc/passwd | \
  awk -F: '{printf "uid=%-5s %-20s home=%-25s shell=%s\n",$3,$1,$6,$7}'

echo "UID 0 accounts (should only be root)"
awk -F: '$3==0{print $1}' /etc/passwd

echo "Empty pass accounts"
sudo awk -F: '$2==""{print $1}' /etc/shadow 2>/dev/null || echo "(need root)"

echo "sudo/wheel members"
getent group sudo wheel 2>/dev/null

echo "/etc/sudoers"
grep -rEv '^\s*(#|$)' /etc/sudoers /etc/sudoers.d 2>/dev/null # i HATE regex good lord

echo "recent logins"
last | head -30

echo "logged in"
who -a

echo
echo "------------- SSH -----------"
echo "sshd config"
sshd -T 2>/dev/null | grep -Ei \
  '(permitrootlogin|passwordauthentication|pubkeyauth|permitemptypass|maxauthtries|allowusers|x11forward)'

echo "ssh auth_keys"
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
  [ -f "$f" ] && echo "==> $f" && cat "$f"
done

echo
echo "------------- PROCESS -----------"
echo "running"
ps -eo pid,ppid,user,stat,lstart,cmd --sort=lstart 2>/dev/null | tail -60

echo "running processes idk about"
ss -tulpnH | grep -Ev '(sshd|httpd|mysqld|mariadbd|systemd|chronyd|dnsmasq|dhclient|rsyslog)' # exclude the ones i know

echo
echo "------------- CRON -----------"
cat /etc/crontab 2>/dev/null
echo "--- /etc/cron.d ---"; ls -la /etc/cron.d/ 2>/dev/null; cat /etc/cron.d/* 2>/dev/null
echo "--- per-user crontabs ---"
for u in $(cut -d: -f1 /etc/passwd); do
  c=$(crontab -l -u "$u" 2>/dev/null) && [ -n "$c" ] && echo "[$u] $c"
done

echo
echo "------------- SYSTEMD -----------"
echo "timers"
systemctl list-timers --all --no-pager 2>/dev/null

echo
echo "------------- FILES -----------"
echo "/tmp and /var/tmp"
ls -laR /tmp /var/tmp 2>/dev/null | head -40

echo
echo "------------- FIREWALL -----------"
if command -v ufw >/dev/null;         then ufw status verbose; fi
if command -v firewall-cmd >/dev/null; then firewall-cmd --list-all 2>/dev/null; fi
if command -v iptables >/dev/null;     then iptables -L -v -n 2>/dev/null | head -50; fi

echo
echo "------------- PACKAGES -----------"
echo "recent installs"
if command -v apt >/dev/null; then
  grep " install " /var/log/dpkg.log 2>/dev/null | grep "$(date +%Y-%m-%d)" | tail -20
elif command -v rpm >/dev/null; then
  rpm -qa --last 2>/dev/null | head -20
fi

echo
echo "------------- LOGS -----------"
echo "recent sudo"
if command -v journalctl >/dev/null; then
  journalctl -u sudo --no-pager --since "-4h" 2>/dev/null | tail -30
else
  grep sudo /var/log/auth.log 2>/dev/null | tail -30
fi

echo "recent ssh"
if command -v journalctl >/dev/null; then
  journalctl -u sshd -u ssh --no-pager --since "-4h" 2>/dev/null | tail -40
else
  grep -Ei '(accept|fail|invalid|break-in)' /var/log/secure /var/log/auth.log 2>/dev/null | tail -40
fi

echo
echo "Scan complete at $(date). run diff on files"