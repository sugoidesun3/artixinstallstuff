#!/bin/sh
disco=$(cat /disco)
rm /disco
starttime=$(cat /starttime)
rm /starttime
isefi=$(test -d /sys/firmware/efi/efivars/)
packages=(
	'git' 'dhcpcd' 'mlocate' 'bc' 'xorg-server' 'xorg-xinit'
	'xorg-xrandr' 'xorg-xsetroot' 'alacritty' 'firefox' 'feh'
	'firefox' 'chromium' 'zsh'
)

echo 'configurando locale e etcs'
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
vim /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
clear

echo '-----> 4 - instalando utilidades pq neh:'
pacman -S cronie doas ${packages[@]}
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
if [ $isefi ]; then
	pacman -S efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
else
	grub-install --target=i386-pc --bootloader-id=grub $disco
fi
grub-mkconfig -o /boot/grub/grub.cfg
clear

echo '-----> feito, soh setar as coisa aq: '
# otimizar o startup time do openrc, capaz de dar uns 5 segundos soh nisso
cp /etc/rc.conf /etc/rc.conf.bak
echo 'rc_parallell="YES"' >> /etc/rc.conf
echo 'rc_send_sighup="YES"' >> /etc/rc.conf
echo 'rc_timeout_stopsec="10"' >> /etc/rc.conf
echo 'rc_send_sigkill="YES"' >> /etc/rc.conf

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
mv /root/dotfiles /home/$username/
clear
minutos=$(bc <<< "($(date +%s)-$starttime)/60")
echo "aeee, demorou soh uns $minutos minuto"
echo 'digo... falta o resto, mas enfim'
echo 'tem yay, picom... alias acho q dah pra automatizar esses tbm'
echo 'ah tem as configuracoes pra limpar a $HOME tbm'
