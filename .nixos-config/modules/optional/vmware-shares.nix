{ ... }:

{
  fileSystems."/mnt/hgfs" = {
    device = ".host:/";
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    options = [
      "defaults"
      "allow_other"
      "uid=1000"
      "gid=100"
      "auto_unmount"
      "nofail"
    ];
  };
}
