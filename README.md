# Personal System Setup Initial Repository

- Github SSH Setup
- Clone .dotfiles repo
- Clone corrensponding system .setup repo

> [!IMPORTANT]
> BIOS Settings - Security Boot: Disable / Boot Sequence: UEFI

## Arch Linux

### System Installation

#### WIFI Setup
```bash
iwctl

# check if the wifi card is power on
device list

# search for available wifi networks
station Device_Name get-networks

# connect 
station Device_Name connect Network_Name

# exit iwctl
exit

# testing connection
ping -c 5 baidu.com
```
### Local Mirrors


Manual Setup
```bash
vim /etc/pacman.d/mirrorlist

# add following to the first line of mirrorlist
Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch
```
Using reflector
```bash
reflector --verbose --country 'China' -l 200 -p https --sort rate --save /etc/pacman.d/mirrorlist
```

pacman -Sy

pacman -S archlinux-keyring

pacman -S archinstall

lsblk

gdisk /dev/nvme0n1

x -> enter expert mode
z -> format target disk
Blank out MBR: y

lsblk -> to check target disk status after formation

archinstall

Disk configuration: 
Partitioning
Use a best-effort default partition layout
'Space' to chose correct target disk'
btrfs
use BTRFS subvolumes with a default structure: yes
Use compression
'Back' to main menu

Swap: Enabled 
Bootloader: Grub
root password: xxxxxx
add user: xxxxxx
Profile: Desktop - Gnome / Minimal
Audio: pipewire
Network configuration: Use NetworkManager
Additional packages: vim git ansible
Timezone: Asia/Shanghai

install

shutdown now


### 
Clone Repo
```bash
git clone https://github.com/curelesss/.init.git
```

Setup Github SSH / clone .dotfiles & .setup.arch
```bash
cd .init
vim sudo
./.init.arch
```
 
