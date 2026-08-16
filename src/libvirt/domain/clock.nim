# libvirt Domain XML type model.
# Time keeping (<clock>) and domain lifecycle events (<on_poweroff> etc).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtClock* = object
    offset*: string              # utc | localtime | timezone | variable
    timezone*: string

  LibvirtOnAction* = enum
    oaDestroy = "destroy"
    oaRestart = "restart"
    oaPreserve = "preserve"
    oaRenameRestart = "rename-restart"
    oaCoredumpDestroy = "coredump-destroy"
    oaCoredumpRestart = "coredump-restart"

  LibvirtEvents* = object
    onPoweroff*: LibvirtOnAction
    onReboot*: LibvirtOnAction
    onCrash*: LibvirtOnAction
    onLockFailure*: string
