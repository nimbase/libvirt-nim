# libvirt Domain XML type model.
# Shared scalar and small helper types used across the domain model.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtMemory* = object
    value*: string
    unit*: string

  LibvirtVcpu* = object
    value*: string
    placement*: string
    cpuset*: string
    current*: string

  LibvirtIothreads* = object
    value*: string
