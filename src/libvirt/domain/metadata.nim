# libvirt Domain XML type model.
# General domain metadata (libvirt formatdomain "General metadata").
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtMetadata* = object
    name*: string
    uuid*: string
    genid*: string
    title*: string
    description*: string
