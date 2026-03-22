{ config, lib, ... }: {

  options.myConfig.diskDevice = lib.mkOption {
    type        = lib.types.str;
    default     = "/dev/sda";
    description = "Target disk device for installation";
  };

  config.disko.devices = {
    disk.main = {
      type   = "disk";
      device = config.myConfig.diskDevice;
      content = {
        type = "gpt";
        partitions = {

          # EFI system partition — required for UEFI boot on ARM
          ESP = {
            size     = "512M";
            type     = "EF00";
            priority = 1;
            content = {
              type         = "filesystem";
              format       = "vfat";
              mountpoint   = "/boot";
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

