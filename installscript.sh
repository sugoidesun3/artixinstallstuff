#!/bin/sh
starttime=$(date +%s)
echo -n 'configurou rede? [Y/n] '
read resp
[[ "x$resp" == "xn" || "x$resp" == "xN" ]] && exit 0

echo 'dxa eu ver....'
ping -c4 8.8.8.8 >/dev/null
[[ "$?" -ne "0" ]] && echo 'configurou o caraio' && exit -1

pacman -S bc

isefi=$(test -d /sys/firmware/efi/efivars/)

echo 'ta, soh ajeitar esses treco aq q eu sei q eu esqueco'
timedatectl set-ntp true
clear

echo '-----> 1 - discos:'
[[ $isefi ]] && echo 'Instalacao EFI' || echo 'Instalacao BIOS'
lsblk
echo -n 'qual disco? '
read nomedisco
disco="/dev/$nomedisco"
echo 'particionando rapidao'
rootpsize=32768
varpsize=$(bc<<<"2*$rootpsize")
# rootpartsize_mib=3072
if [ $isefi ]; then

printf "mklabel gpt
unit mib
mkpart primary 1 512
name 1 boot
set 1 BOOT on
mkpart primary 512 $(bc <<< "512+$rootpsize")
name 2 root
mkpart primary $(bc <<< "512+$rootpsize") $(bc <<< "512+$rootpsize+$varpsize")
name 3 var
mkpart primary $(bc <<< "512+$rootpsize+$varpsize") -1
name 4 home
" | parted -a optimal "$disco"
else

printf "mklabel msdos
unit mib
mkpart primary 1 512
set 1 BOOT on
mkpart primary 512 $(bc <<< "512+$rootpsize")
mkpart primary $(bc <<< "512+$rootpsize") $(bc <<< "512+$rootpsize+$varpsize")
mkpart primary $(bc <<< "512+$rootpsize+$varpsize") -1
" | parted -a optimal "$disco"
fi
echo 'formatando discos...'
mkfs.fat -F 32 "${disco}1"
mkfs.ext4 "${disco}2"
mkfs.ext4 "${disco}3"
mkfs.ext4 "${disco}4"
[[ $? -ne 0 ]] && echo 'cagou aq nos disco' && exit -1
clear

echo '-----> 2 - montando os treco & instalando o sistema:'
mount "${disco}2" /mnt
mkdir /mnt/{home,boot,var}
mount "${disco}1" /mnt/boot
mount "${disco}3" /mnt/var
mount "${disco}4" /mnt/home
vim /etc/pacman.d/mirrorlist
echo 'esse demora um cadin'
pacstrap /mnt base linux-zen linux-zen-headers linux-firmware vim man-pages
[[ $? -ne 0 ]] && echo 'dafuq' && exit -1
clear
echo '-----> 3 - configuracoes basicas:'
echo 'gerando o fstab...'
genfstab -U /mnt >> /mnt/etc/fstab
echo 'vou aproveitar e levar os arquivo pra la'
mkdir -p /mnt/root
echo $starttime > /mnt/starttime
echo $disco > /mnt/disco
mv dotfiles.tar.gz /mnt/root/
cp postchroot.sh /mnt/
echo 'vamo la'
arch-chroot /mnt "/postchroot.sh"
rm /mnt/postchroot.sh
arch-chroot /mnt
