# Tests for libvirt Domain XML rendering.
#
# Verifies that typed LibvirtDomain objects render to valid libvirt XML
# via `toXML`.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/[unittest, strutils]
import ../src/libvirt

# ------------------------------------------------------------------
# Basic object construction
# ------------------------------------------------------------------

suite "toXML — object fields":
  test "domain type and id":
    let d = LibvirtDomain(virtType: "kvm", id: "1")
    check d.virtType == "kvm"
    check d.id == "1"

  test "metadata fields":
    let d = LibvirtDomain(
      virtType: "kvm",
      metadata: LibvirtMetadata(
        name: "MyGuest",
        uuid: "4dea22b3-1234-5678-9abc-def012345678",
        title: "Test VM",
        description: "A test virtual machine"
      )
    )
    check d.metadata.name == "MyGuest"
    check d.metadata.uuid == "4dea22b3-1234-5678-9abc-def012345678"
    check d.metadata.title == "Test VM"
    check d.metadata.description == "A test virtual machine"

  test "memory and currentMemory":
    let d = LibvirtDomain(
      virtType: "kvm",
      memory: LibvirtMemory(value: "1048576", unit: "KiB"),
      currentMemory: LibvirtMemory(value: "524288", unit: "KiB")
    )
    check d.memory.value == "1048576"
    check d.memory.unit == "KiB"
    check d.currentMemory.value == "524288"
    check d.currentMemory.unit == "KiB"

  test "vcpu":
    let d = LibvirtDomain(
      virtType: "kvm",
      vcpu: LibvirtVcpu(value: "4", placement: "static", cpuset: "0-3", current: "2")
    )
    check d.vcpu.value == "4"
    check d.vcpu.placement == "static"
    check d.vcpu.cpuset == "0-3"
    check d.vcpu.current == "2"

  test "os section":
    let d = LibvirtDomain(
      virtType: "kvm",
      os: LibvirtOS(
        osType: "hvm", arch: "x86_64", machine: "pc",
        boot: @[bdHardDisk, bdCdrom]
      )
    )
    check d.os.osType == "hvm"
    check d.os.arch == "x86_64"
    check d.os.machine == "pc"
    check d.os.boot.len == 2

  test "clock and events":
    let d = LibvirtDomain(
      virtType: "kvm",
      clock: LibvirtClock(offset: "utc"),
      events: LibvirtEvents(
        onPoweroff: oaDestroy, onReboot: oaRestart, onCrash: oaDestroy
      )
    )
    check d.clock.offset == "utc"
    check d.events.onPoweroff == oaDestroy
    check d.events.onReboot == oaRestart

  test "features":
    let d = LibvirtDomain(
      virtType: "kvm",
      features: LibvirtFeatures(acpi: true, apic: true)
    )
    check d.features.acpi == true
    check d.features.apic == true
    check d.features.pae == false

  test "single disk":
    let d = LibvirtDomain(
      virtType: "kvm",
      disks: @[LibvirtDisk(
        diskType: "file", device: "disk",
        driverName: "qemu", driverType: "qcow2",
        sourceFile: "/var/lib/libvirt/images/guest.qcow2",
        targetDev: "vda", targetBus: "virtio"
      )]
    )
    check d.disks.len == 1
    check d.disks[0].diskType == "file"
    check d.disks[0].device == "disk"
    check d.disks[0].driverName == "qemu"
    check d.disks[0].driverType == "qcow2"
    check d.disks[0].sourceFile == "/var/lib/libvirt/images/guest.qcow2"
    check d.disks[0].targetDev == "vda"
    check d.disks[0].targetBus == "virtio"

  test "interface":
    let d = LibvirtDomain(
      virtType: "kvm",
      interfaces: @[LibvirtInterface(
        ifaceType: "network",
        sourceNetwork: "default",
        mac: "52:54:00:12:34:56",
        model: "virtio"
      )]
    )
    check d.interfaces.len == 1
    check d.interfaces[0].ifaceType == "network"
    check d.interfaces[0].sourceNetwork == "default"
    check d.interfaces[0].mac == "52:54:00:12:34:56"
    check d.interfaces[0].model == "virtio"

  test "cpu model":
    let d = LibvirtDomain(
      virtType: "qemu",
      cpu: LibvirtCpu(model: "cortex-a57")
    )
    check d.cpu.model == "cortex-a57"

  test "memory backing and filesystems":
    let d = LibvirtDomain(
      virtType: "qemu",
      memoryBacking: LibvirtMemoryBacking(sourceType: "memfd", accessMode: "shared"),
      filesystems: @[LibvirtFilesystem(
        fsType: "mount", accessmode: "passthrough",
        driverType: "virtiofs", driverQueue: "1024",
        sourceDir: "/host/code", targetDir: "code"
      )]
    )
    check d.memoryBacking.sourceType == "memfd"
    check d.filesystems.len == 1
    check d.filesystems[0].targetDir == "code"

# ------------------------------------------------------------------
# XML rendering
# ------------------------------------------------------------------

suite "toXML — XML rendering":
  test "minimal domain":
    let d = LibvirtDomain(
      virtType: "kvm",
      metadata: LibvirtMetadata(name: "test")
    )
    check toXML(d) == "<domain type=\"kvm\"><name>test</name></domain>"

  test "full domain XML matches expected":
    let d = LibvirtDomain(
      virtType: "kvm",
      id: "1",
      metadata: LibvirtMetadata(
        name: "MyGuest",
        uuid: "4dea22b3-1234-5678-9abc-def012345678"
      ),
      memory: LibvirtMemory(value: "1048576", unit: "KiB"),
      vcpu: LibvirtVcpu(value: "2", placement: "static"),
      os: LibvirtOS(
        osType: "hvm", arch: "x86_64", machine: "pc",
        boot: @[bdHardDisk]
      ),
      features: LibvirtFeatures(acpi: true, apic: true),
      disks: @[LibvirtDisk(
        diskType: "file", device: "disk",
        driverName: "qemu", driverType: "qcow2",
        sourceFile: "/var/lib/libvirt/images/guest.qcow2",
        targetDev: "vda", targetBus: "virtio"
      )],
      interfaces: @[LibvirtInterface(
        ifaceType: "network",
        sourceNetwork: "default",
        mac: "52:54:00:12:34:56",
        model: "virtio"
      )]
    )
    let expected = "<domain type=\"kvm\" id=\"1\">" &
      "<name>MyGuest</name>" &
      "<uuid>4dea22b3-1234-5678-9abc-def012345678</uuid>" &
      "<memory unit=\"KiB\">1048576</memory>" &
      "<vcpu placement=\"static\">2</vcpu>" &
      "<os><type arch=\"x86_64\" machine=\"pc\">hvm</type><boot dev=\"hd\"/></os>" &
      "<features><acpi/><apic/></features>" &
      "<devices>" &
        "<disk type=\"file\" device=\"disk\">" &
          "<driver name=\"qemu\" type=\"qcow2\"/>" &
          "<source file=\"/var/lib/libvirt/images/guest.qcow2\"/>" &
          "<target dev=\"vda\" bus=\"virtio\"/>" &
        "</disk>" &
        "<interface type=\"network\">" &
          "<source network=\"default\"/>" &
          "<mac address=\"52:54:00:12:34:56\"/>" &
          "<model type=\"virtio\"/>" &
        "</interface>" &
      "</devices>" &
      "</domain>"
    check toXML(d) == expected

  test "aarch64 guest with UEFI loader, cpu and qemu args":
    let d = LibvirtDomain(
      virtType: "qemu",
      metadata: LibvirtMetadata(name: "arm"),
      memory: LibvirtMemory(value: "2097152", unit: "KiB"),
      vcpu: LibvirtVcpu(value: "2", placement: "static"),
      os: LibvirtOS(
        osType: "hvm", arch: "aarch64", machine: "virt",
        loader: "/opt/local/share/qemu/edk2-aarch64-code.fd",
        boot: @[bdHardDisk]
      ),
      cpu: LibvirtCpu(model: "cortex-a57"),
      emulator: "/opt/local/bin/qemu-system-aarch64",
      qemuArgs: @["-netdev", "user,id=hostnet0"]
    )
    let xml = toXML(d)
    check xml.contains("<type arch=\"aarch64\" machine=\"virt\">hvm</type>")
    check xml.contains("<loader>/opt/local/share/qemu/edk2-aarch64-code.fd</loader>")
    check xml.contains("<cpu><model>cortex-a57</model></cpu>")
    check xml.contains("<emulator>/opt/local/bin/qemu-system-aarch64</emulator>")
    check xml.contains("<qemu:arg value='-netdev'/>")

  test "memory backing and filesystem render":
    let d = LibvirtDomain(
      virtType: "qemu",
      metadata: LibvirtMetadata(name: "shared"),
      memoryBacking: LibvirtMemoryBacking(sourceType: "memfd", accessMode: "shared"),
      filesystems: @[LibvirtFilesystem(
        fsType: "mount", accessmode: "passthrough",
        driverType: "virtiofs", driverQueue: "1024",
        sourceDir: "/host/code", targetDir: "code"
      )]
    )
    let xml = toXML(d)
    check xml.contains("<memoryBacking><source type=\"memfd\"/><access mode=\"shared\"/></memoryBacking>")
    check xml.contains("<filesystem type=\"mount\" accessmode=\"passthrough\">")
    check xml.contains("<driver type=\"virtiofs\" queue=\"1024\"/>")
    check xml.contains("<source dir=\"/host/code\"/>")
    check xml.contains("<target dir=\"code\"/>")

  test "escaping in text content":
    let d = LibvirtDomain(
      virtType: "qemu",
      metadata: LibvirtMetadata(name: "a&b")
    )
    check toXML(d).contains("&amp;")

  test "$ operator":
    let d = LibvirtDomain(
      virtType: "qemu",
      metadata: LibvirtMetadata(name: "x")
    )
    check $d == toXML(d)

  test "non-default on_poweroff is emitted":
    let d = LibvirtDomain(
      virtType: "kvm",
      metadata: LibvirtMetadata(name: "test"),
      events: LibvirtEvents(onPoweroff: oaPreserve)
    )
    check toXML(d).contains("<on_poweroff>preserve</on_poweroff>")

  test "default events are omitted":
    let d = LibvirtDomain(
      virtType: "kvm",
      metadata: LibvirtMetadata(name: "test")
    )
    check "<on_poweroff>" notin toXML(d)
    check "<on_reboot>" notin toXML(d)
    check "<on_crash>" notin toXML(d)
