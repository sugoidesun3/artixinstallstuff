#!/bin/sh
echo -n 'configurou rede? [y/N] '
read resp
if [ "x$resp" != "xy" ] && [ "x$resp" != "xY" ]; then
	exit 0
fi

echo 'dxa eu ver.....'
ping -c4 8.8.8.8>/dev/null
[[ "$?" -ne "0" ]] && echo 'configurou o caraio' && exit -1

isefi=$(test -d /sys/firmware/efi/efivars/)
[[ $isefi ]] && echo 'Instalacao EFI' || echo 'Instalacao BIOS'

echo 'ta, soh ajeitar esses treco aq q eu sei q eu esqueceria'
timedatectl set-ntp true
clear

echo '-----> 1 - discos:'
lsblk
echo -n 'qual disco? '
read nomedisco
disco="/dev/$nomedisco"
echo 'particionando rapidao'
if [[ "$isefi" == "y" || "$isefi" == "Y" ]]; then

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
pacstrap /mnt base linux linux-firmware vim
clear
echo '-----> 3 - configuracoes basicas:'
echo 'gerando o fstab...'
genfstab -U /mnt >> /mnt/etc/fstab
echo 'vou aproveitar e levar os arquivo pra la'
mkdir -p /mnt/root
mv dotfiles /mnt/root/
mv postchroot.sh /mnt/
echo 'vamo la no chroot'
arch-chroot /mnt "./postchroot.sh $disco"
