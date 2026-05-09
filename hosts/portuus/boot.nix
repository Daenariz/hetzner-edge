{
  boot.loader.grub.memtest86.enable = true;

  # Workaround for AMD Ryzen C-state freeze bug on X370 boards
  boot.kernelParams = [ "processor.max_cstate=1" "idle=nomwait" ];

  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    configurationLimit = 20;
    mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
    ];
  };

  boot.enableContainers = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  # TODO: boot.kernelPackages = LTS;
}
