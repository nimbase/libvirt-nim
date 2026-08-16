# libvirt Domain XML type model.
# Operating system booting (<os> element).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtBootDevice* = enum
    bdFloppy = "fd"
    bdHardDisk = "hd"
    bdCdrom = "cdrom"
    bdNetwork = "network"

  LibvirtOS* = object
    osType*: string              # hvm, exe, ...
    arch*: string
    machine*: string
    firmware*: string            # bios | efi
    loader*: string
    nvram*: string
    boot*: seq[LibvirtBootDevice]
    kernel*: string
    initrd*: string
    cmdline*: string
