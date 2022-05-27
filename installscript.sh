#!/bin/sh

start=$(date)
echo "vamo la, comecou em $start"
echo -n 'configurou rede? [y/N] '
read resp
if [ "x$resp" != "xy" ] && [ "x$resp" != "xY" ]; then
	exit 0
fi
ls /sys/firmware/efi/efivars/
echo 'eh efi? [y/N]'
read isefi

echo 'dxa eu ver'
ping -c4 8.8.8.8>/dev/null
[[ "$?" -ne "0" ]] && echo 'configurou o caraio' && exit
echo 'ta, soh ajeitar esses treco aq q tu esqueceu'
timedatectl set-ntp true
clear

echo '-----> 1 - discos:'
lsblk
echo -n 'qual disco? '
read $disco
echo 'particionando rapidao'
if [ "$isefi" == "y" || "$isefi" == "Y" ]; then

printf "mklabel gpt
unit mib
mkpart primary 1 512
name 1 boot
set 1 BOOT on
mkpart primary 512 33280
name 2 root
mkpart primary 33280 -1
name 3 home
w
" | parted -a optimal "$disco"
else

printf "unit mib
mkpart primary 1 512
name 1 boot
set 1 BOOT on
mkpart primary 512 33280
name 2 root
mkpart primary 33280 -1
name 3 home
w
" | parted -a optimal "$disco"
fi
echo 'formatando discos...'
mkfs.fat -F 32 "${disco}1"
mkfs.ext4 "${disco}2"
mkfs.ext4 "${disco}3"
clear
echo '-----> 2 - montando os treco & instalando o sistema:'
mount "${disco}2" /mnt
mkdir /mnt/{home,boot}
mount "${disco}1" /mnt/boot
mount "${disco}3" /mnt/home
vim /etc/pacman.d/mirrorlist
echo 'esse demora um cadin'
basestrap /mnt base base-devel openrc elogind-openrc linux linux-firmware vim git
clear
echo '-----> 3 - configuracoes basicas:'
echo 'gerando o fstab...'
fstabgen -U /mnt >> /mnt/etc/fstab
echo 'vamo la no chroot'
artools-chroot /mnt
echo -n 'shell errada? [y/N]'
read wrong
[[ "$wrong" == "y" || "$wrong" == "Y" ]] && bash
vim /etc/pacman.d/mirrorlist
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
vim /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
pacman -S cronie dhcpcd mlocate
rc-update add cronie default
clear

echo '-----> 4 - instalando utilidades pq neh:'
pacman -S git doas
echo 'permit persist :wheel' > /etc/doas.conf
pacman -R sudo
chown -c root:root /etc/doas.conf
chmod -c 0400 /etc/doas.conf
echo 'complete -cf doas' >> /etc/bash.bashrc
ln -s $(which doas) /usr/bin/sudo
# o fato de colocarem "sudo" harcoded em software me buga d+
# enfim isso daqui resolve
ln -sf k
clear

echo '-----> 5 - instalando grub:'
pacman -S grub
if [[ "$isefi" == "y" || "$isefi" == "Y" ]]; then
	pacman -S efibootmgr
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
else
	grub-install --target=i386-pc $disco --bootloader-id=grub
fi
grub-mkconfig -o /boot/grub/grub.cfg
clear

echo '-----> feito, soh setar as coisa aq: '
echo -n 'hostname? (pensa bem, hein) '
read hostname
echo $hostname > /etc/hostname
printf "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.0.1\t$hostname.localdomain $hostname" >> /etc/hosts
passwd
echo 'ah, nome do usuario: '
read username
useradd -m -G users,wheel,audio -s /bin/bash $username
passwd $username
clear

echo "aeee, demorou soh uns $minutos minuto"
