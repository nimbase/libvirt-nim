# libvirt Domain XML type model.
# Time keeping (<clock>) and domain lifecycle events (<on_poweroff> etc).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtClock* = object
    offset*: string              # utc | localtime | timezone | variable
    timezone*: string
    kvmclockPresent*: string     # yes | no (timer name='kvmclock')
    hpetPresent*: string         # yes | no
    rtcTickPolicy*: string       # catchup | delay
    pitTickPolicy*: string       # catchup | delay

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
