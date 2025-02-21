# Personal System Setup Initial Repository

- Github SSH Setup
- Clone .dotfiles repo
- Clone corrensponding system .setup repo

> [!IMPORTANT]
> BIOS Settings - Security Boot: Disable / Boot Sequence: UEFI

BIOS - boot sequence - UEFI

iwctl

device list

station Device_Name get-networks

station Device_Name connect Network_Name

exit

ping -c 5 baidu.com

reflector --verbose --country 'China' -l 200 -p https --sort rate --save /etc/pacman.d/mirrorlist

vim /etc/pacman.d/mirrorlist

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

## Arch Linux

### System Installation

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
 
