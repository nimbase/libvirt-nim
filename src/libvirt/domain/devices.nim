# libvirt Domain XML type model.
# Device types (<devices> children).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtDisk* = object
    diskType*: string            # file | block | dir | network
    device*: string              # disk | cdrom | floppy | lun
    driverName*: string
    driverType*: string
    sourceFile*: string
    sourceDev*: string
    targetDev*: string
    targetBus*: string
    readonly*: bool

  LibvirtInterface* = object
    ifaceType*: string           # network | bridge | user | direct | ...
    sourceNetwork*: string
    sourceBridge*: string
    mac*: string
    model*: string
    targetDev*: string

  LibvirtSerial* = object
    targetPort*: string
    sourcePath*: string
    sourceType*: string

  LibvirtConsole* = object
    targetType*: string
    targetPort*: string
    sourcePath*: string
    sourceType*: string

  LibvirtGraphics* = object
    graphicsType*: string        # vnc | spice | ...
    port*: string
    listen*: string
    autoport*: string
    passwd*: string

  LibvirtChannel* = object
    channelType*: string         # unix | ...
    sourceMode*: string          # bind | connect
    sourcePath*: string
    targetType*: string          # virtio
    targetName*: string          # org.qemu.guest_agent.0

  LibvirtFilesystem* = object
    fsType*: string              # mount | bind
    accessmode*: string          # passthrough | mapped
    driverType*: string          # virtiofs
    driverQueue*: string         # e.g. "1024"
    sourceDir*: string
    sourceSocket*: string
    targetDir*: string           # mount tag
