{ config, lib, ... }: {

  options.myConfig.diskDevice = lib.mkOption {
    type        = lib.types.str;
    default     = "/dev/nvme0n1";
    description = "Target disk device for installation";
  };

  config.disko.devices = {
    disk.main = {
      type   = "disk";
      device = config.myConfig.diskDevice;
      content = {
        type = "gpt";
        partitions = {

          # GRUB on GPT needs this tiny partition for the bootloader code
          # even when booting UEFI — keeps both BIOS and UEFI working
          MBR = {
            size = "1M";
            type = "EF02";    # BIOS boot partition — GRUB stage 1.5
            priority = 1;     # must be first on disk
          };

          # EFI system partition — for UEFI GRUB
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type         = "filesystem";
              format       = "vfat";
              mountpoint   = "/boot/efi";
              mountOptions = [ "umask=0077" ];
            };
          };

          # Root — takes everything remaining
          root = {
            size = "100%";
            content = {
              type         = "filesystem";
              format       = "ext4";
              mountpoint   = "/";
              mountOptions = [ "noatime" ];
            };
          };

        };
      };
    };
  };

}
