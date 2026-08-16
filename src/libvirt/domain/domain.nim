# libvirt Domain XML type model.
# The top-level LibvirtDomain object aggregating all sections.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common
import ./metadata
import ./os
import ./cpu
import ./clock
import ./devices

type
  LibvirtDomain* = object
    virtType*: string            # hypervisor: kvm, qemu, xen, hvf, ...
    id*: string
    metadata*: LibvirtMetadata
    memory*: LibvirtMemory
    currentMemory*: LibvirtMemory
    vcpu*: LibvirtVcpu
    iothreads*: LibvirtIothreads
    os*: LibvirtOS
    cpu*: LibvirtCpu
    features*: LibvirtFeatures
    clock*: LibvirtClock
    events*: LibvirtEvents
    disks*: seq[LibvirtDisk]
    interfaces*: seq[LibvirtInterface]
    serials*: seq[LibvirtSerial]
    consoles*: seq[LibvirtConsole]
    graphics*: seq[LibvirtGraphics]
