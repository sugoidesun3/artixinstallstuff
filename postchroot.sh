#!/bin/sh
disco=$(cat /disco)
starttime=$(cat /starttime)
isefi=$(test -d /sys/firmware/efi/efivars/)
pacman -S coreutils
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 5" /etc/pacman.conf
packages=(
	'git' 'dhcpcd' 'mlocate' 'bc' 'feh' 'zsh' 'gcc' 'firefox'
	'xorg-server' 'xorg-xinit' 'xorg-xrandr' 'xorg-xsetroot'
	'cronie' 'doas' 'alacritty' 'which' 'fakeroot' 'make' 'grep'
	'gzip' 'gawk' 'findutils' 'bison' 'automake' 'autoconf' 'sed'
	'pkgconf' 'file' 'm4' 'libtool' 'groff' 'patch'
)

echo 'configurando locale e etcs'
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
clear

echo '-----> 4 - instalando utilidades pq neh:'
pacman -S ${packages[@]}
[[ ! $? ]] && echo 'ih rapaz' && exit -1
systemctl enable cronie.service
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
echo 'especificacoes do XDG (limpar a $HOME um cadin)'
printf 'XDG_CONFIG_HOME="$HOME"/.config
XDG_CACHE_HOME="$HOME"/.local/cache
XDG_DATA_HOME="$HOME"/.local/share
XDG_STATE_HOME="$HOME"/.local/state
' >> /etc/profile
printf 'XDG_CONFIG_HOME="$HOME"/.config
XDG_CACHE_HOME="$HOME"/.local/cache
XDG_DATA_HOME="$HOME"/.local/share
XDG_STATE_HOME="$HOME"/.local/state
' >> /etc/zsh/zshenv
echo 'ZDOTDIR=$HOME/.config/zsh' >> /etc/zsh/zshenv
printf 'if [[ $UID -ge 1000 && -d $HOME/.local/bin && -z $(echo $PATH | grep -o $HOME/.local/bin) ]]
then
    export PATH="${PATH}:$HOME/.local/bin"
fi
' >> /etc/profile

hostname='immaterium'
username='khorne'

echo $hostname > /etc/hostname
printf "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.0.1\t$hostname.localdomain $hostname" >> /etc/hosts
passwd
useradd -m -G users,wheel,audio,video -s /bin/bash $username
passwd $username
mv /root/dotfiles.tar.gz /home/$username/
rm /disco
rm /starttime

cd /home/$username/
mkdir -p .config/suckless
tar xpvf dotfiles.tar.gz

mv dotfiles/{VSCodium,alacritty,git,vim,zsh,X11,rc} .config/
mv dotfiles/{dwm,dwmblocks-async,dmenu} .config/suckless/

mkdir -p {Stuff/{projects,media/{videos,images,wallpapers},books},Downloads,Music}
mv dotfiles/wall.png Stuff/media/wallpapers/

chown -R $username .
clear

minutos=$(bc <<< "($(date +%s)-$starttime)/60")
echo "* aeee, demorou soh uns $minutos minuto"
