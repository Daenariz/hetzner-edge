{
  boot = {
    loader.grub = {
      enable = true;
      memtest86.enable = true;
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

    # Workaround for AMD Ryzen C-state freeze bug on X370 boards
    kernelParams = [
      "processor.max_cstate=1"
      "idle=nomwait"
    ];

    enableContainers = true;

    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    # TODO: boot.kernelPackages = LTS;
  };
}
