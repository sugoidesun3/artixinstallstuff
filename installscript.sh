#!/bin/sh
pacman -S bc
starttime=$(date +%s)
echo -n 'configurou rede? [Y/n] '
read resp
if [[ "x$resp" == "xn" || "x$resp" == "xN" ]]; then
	exit 0
fi

echo 'dxa eu ver....'
ping -c4 8.8.8.8 >/dev/null
[[ "$?" -ne "0" ]] && echo 'configurou o caraio' && exit -1

isefi=$(test -d /sys/firmware/efi/efivars/)
[[ $isefi ]] && echo 'Instalacao EFI' || echo 'Instalacao BIOS'

echo 'ta, soh ajeitar esses treco aq q eu sei q eu esqueco'
timedatectl set-ntp true
clear

echo '-----> 1 - discos:'
lsblk
echo -n 'qual disco? '
read nomedisco
disco="/dev/$nomedisco"
echo 'particionando rapidao'
rootpartsize_mib=32768
# rootpartsize_mib=3072
if [ $isefi ]; then

printf "mklabel gpt
unit mib
mkpart primary 1 512
name 1 boot
set 1 BOOT on
mkpart primary 512 $(bc <<< "512+$rootpartsize_mib")
name 2 root
mkpart primary $(bc <<< "512+$rootpartsize_mib") -1
name 3 home
" | parted -a optimal "$disco"
else

printf "mklabel msdos
unit mib
mkpart primary 1 512
name 1 boot
set 1 BOOT on
mkpart primary 512 $(bc <<< "512+$rootpartsize_mib")
name 2 root
mkpart primary $(bc <<< "512+$rootpartsize_mib") -1
name 3 home
" | parted -a optimal "$disco"
fi
echo 'formatando discos...'
mkfs.fat -F 32 "${disco}1"
mkfs.ext4 "${disco}2"
mkfs.ext4 "${disco}3"
echo 'deu caca? '
read deucaca
[![ -z $deucaca ]] && exit -1
clear
echo '-----> 2 - montando os treco & instalando o sistema:'
mount "${disco}2" /mnt
mkdir /mnt/{home,boot}
mount "${disco}1" /mnt/boot
mount "${disco}3" /mnt/home
vim /etc/pacman.d/mirrorlist
echo 'esse demora um cadin'
basestrap /mnt base linux-zen linux-zen-headers linux-firmware vim openrc elogind-openrc
clear
echo '-----> 3 - configuracoes basicas:'
echo 'gerando o fstab...'
fstabgen -U /mnt >> /mnt/etc/fstab
echo 'vou aproveitar e levar os arquivo pra la'
mkdir -p /mnt/root
echo $starttime > /mnt/starttime
echo $disco > /mnt/disco
cp -r dotfiles /mnt/root/dotfiles
cp -r postchroot.sh /mnt/postchroot.sh
echo 'vamo la'
sleep 1
artix-chroot /mnt "/postchroot.sh"
