# libvirt Domain XML type model.
# CPU allocation, model and topology.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

type
  LibvirtCpu* = object
    mode*: string                # host-passthrough | host-model | custom
    check*: string               # none | full | partial
    model*: string
    vendor*: string
    topologySockets*, topologyCores*, topologyThreads*: string
    featurePolicy*: seq[tuple[name, policy: string]]

  LibvirtFeatures* = object
    acpi*: bool
    apic*: bool
    pae*: bool
    pvspinlock*: string
    kvmHidden*: bool
    vmport*: string             # off | on
