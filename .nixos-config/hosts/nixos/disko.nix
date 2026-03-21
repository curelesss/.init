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

          # Required for GRUB on GPT in BIOS mode
          MBR = {
            size     = "1M";
            type     = "EF02";
            priority = 1;
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
