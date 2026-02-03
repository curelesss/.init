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

### Pre-Install
```bash
# sync package manager db 
pacman -Sy

# acquire keying
pacman -S archlinux-keyring

# update install script
pacman -S archinstall
```

### Format Target Disk

- identify target disk
```bash
lsblk
```

- format using gdisk
```bash
gdisk /dev/nvme0n1
```
  - 'x' -> enter expert mode
  - 'z' -> format target disk
  - Blank out MBR: y

  - finally using 'lsblk' comand again -> to check target disk status after formation

# format using cfdisk
```bash
cfdisk /dev/nvme0n1
```

### Install Arch Linux

- run install script
```bash
archinstall
```

Installation Settings
- Disk configuration: 
-- Partitioning
-- Use a best-effort default partition layout
-- 'Space' to chose correct target disk'
-- btrfs
-- use BTRFS subvolumes with a default structure: yes
-- Use compression
--'Back' to main menu

- Swap: Enabled 
- Bootloader: Grub
- root password: xxxxxx
- add user: xxxxxx
- Profile: Desktop - Gnome / Minimal
- Audio: pipewire
- Network configuration: Use NetworkManager
- Additional packages: vim git ansible
- Timezone: Asia/Shanghai

- install

Finally, shutdown system using '$ shutdown now` command, and remove install media.

### Initial Setup

- Clone Repo
```bash
git clone https://github.com/curelesss/.init.git
cd .init
```

- Setup locale / install Chinese Font / Setup several Chinese Character
```bash
./arch.0.font.sh
```

Setup Github SSH
```bash
vim sudo
./arch.1.github.sh
```
 
