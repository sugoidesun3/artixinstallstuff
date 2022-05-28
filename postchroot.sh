#!/bin/sh
[[ -z $1 ]] && echo 'mula, eh /dev/sda?' && exit -1
disco=$1
starttime=$2
isefi=$(test -d /sys/firmware/efi/efivars/)

echo 'configurando locale e etcs'
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
vim /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
clear

echo '-----> 4 - instalando utilidades pq neh:'
pacman -S cronie dhcpcd mlocate git doas
rc-update add cronie default
echo 'permit persist :wheel' > /etc/doas.conf
pacman -R sudo 2>/dev/null
chown -c root:root /etc/doas.conf
chmod -c 0400 /etc/doas.conf
echo 'complete -cf doas' >> /etc/bash.bashrc
# o fato de colocarem "sudo" harcoded em software me buga d+
# enfim isso daqui resolve problema de compatibilidade facil
ln -s $(which doas) /usr/bin/sudo
clear

echo '-----> 5 - instalando grub:'
pacman -S grub
if [[ "$isefi" == "y" || "$isefi" == "Y" ]]; then
	pacman -S efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
else
	grub-install --target=i386-pc --bootloader-id=grub $disco
fi
grub-mkconfig -o /boot/grub/grub.cfg
clear

echo '-----> feito, soh setar as coisa aq: '
echo -n 'hostname? (pensa bem, hein) '
read hostname
echo $hostname > /etc/hostname
printf "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.0.1\t$hostname.localdomain $hostname" >> /etc/hosts
echo -n 'senha root: '
passwd
echo -n 'usuario: '
read username
useradd -m -G users,wheel,audio,video -s /bin/bash $username
passwd $username
clear
minutos=$(bc <<< "$(date +%s)-$starttime")
echo "aeee, demorou soh uns $minutos minuto"
