# Tests for the libvirt Domain XML DSL.
#
# Verifies that the DSL macro builds a typed LibvirtDomain object and
# that the XML renderer produces valid libvirt XML.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/[unittest, strutils]
import ../src/libvirt

# ------------------------------------------------------------------
# Basic object construction
# ------------------------------------------------------------------

suite "xmldsl — object fields":
  test "domain type and id":
    let d = domain(`type`="kvm", id="1")
    check d.virtType == "kvm"
    check d.id == "1"

  test "metadata fields":
    let d = domain(`type`="kvm"):
      name: "MyGuest"
      uuid: "4dea22b3-1234-5678-9abc-def012345678"
      title: "Test VM"
      description: "A test virtual machine"
    check d.metadata.name == "MyGuest"
    check d.metadata.uuid == "4dea22b3-1234-5678-9abc-def012345678"
    check d.metadata.title == "Test VM"
    check d.metadata.description == "A test virtual machine"

  test "memory and currentMemory":
    let d = domain(`type`="kvm"):
      memory unit="KiB": "1048576"
      currentMemory unit="KiB": "524288"
    check d.memory.value == "1048576"
    check d.memory.unit == "KiB"
    check d.currentMemory.value == "524288"
    check d.currentMemory.unit == "KiB"

  test "vcpu":
    let d = domain(`type`="kvm"):
      vcpu placement="static", cpuset="0-3", current="2": "4"
    check d.vcpu.value == "4"
    check d.vcpu.placement == "static"
    check d.vcpu.cpuset == "0-3"
    check d.vcpu.current == "2"

  test "os section":
    let d = domain(`type`="kvm"):
      os:
        `type` arch="x86_64", machine="pc": "hvm"
        boot dev="hd"
        boot dev="cdrom"
    check d.os.osType == "hvm"
    check d.os.arch == "x86_64"
    check d.os.machine == "pc"
    check d.os.boot.len == 2

  test "clock and events":
    let d = domain(`type`="kvm"):
      clock offset="utc"
      on_poweroff: "destroy"
      on_reboot: "restart"
      on_crash: "destroy"
    check d.clock.offset == "utc"
    check d.events.onPoweroff == oaDestroy
    check d.events.onReboot == oaRestart

  test "features — block form":
    let d = domain(`type`="kvm"):
      features:
        acpi
        apic
    check d.features.acpi == true
    check d.features.apic == true
    check d.features.pae == false

  test "features — bracket idents":
    let d = domain(`type`="kvm"):
      features: [acpi, apic]
    check d.features.acpi == true
    check d.features.apic == true

  test "features — bracket strings comma":
    let d = domain(`type`="kvm"):
      features: ["acpi", "apic"]
    check d.features.acpi == true
    check d.features.apic == true

  test "features — bracket strings space":
    let d = domain(`type`="kvm"):
      features: ["acpi" "apic"]
    check d.features.acpi == true
    check d.features.apic == true

  test "single disk":
    let d = domain(`type`="kvm"):
      devices:
        disk `type`="file", device="disk":
          driver name="qemu", `type`="qcow2"
          source file="/var/lib/libvirt/images/guest.qcow2"
          target dev="vda", bus="virtio"
    check d.disks.len == 1
    check d.disks[0].diskType == "file"
    check d.disks[0].device == "disk"
    check d.disks[0].driverName == "qemu"
    check d.disks[0].driverType == "qcow2"
    check d.disks[0].sourceFile == "/var/lib/libvirt/images/guest.qcow2"
    check d.disks[0].targetDev == "vda"
    check d.disks[0].targetBus == "virtio"

  test "interface":
    let d = domain(`type`="kvm"):
      devices:
        `interface` `type`="network":
          source network="default"
          mac address="52:54:00:12:34:56"
          model `type`="virtio"
    check d.interfaces.len == 1
    check d.interfaces[0].ifaceType == "network"
    check d.interfaces[0].sourceNetwork == "default"
    check d.interfaces[0].mac == "52:54:00:12:34:56"
    check d.interfaces[0].model == "virtio"

# ------------------------------------------------------------------
# XML rendering
# ------------------------------------------------------------------

suite "xmldsl — XML rendering":
  test "minimal domain":
    let d = domain(`type`="kvm"):
      name: "test"
    check d.xml == "<domain type=\"kvm\"><name>test</name></domain>"

  test "full domain XML matches expected":
    let d = domain(`type`="kvm", id="1"):
      name: "MyGuest"
      uuid: "4dea22b3-1234-5678-9abc-def012345678"
      memory unit="KiB": "1048576"
      vcpu placement="static": "2"
      os:
        `type` arch="x86_64", machine="pc": "hvm"
        boot dev="hd"
      features:
        acpi
        apic
      devices:
        disk `type`="file", device="disk":
          driver name="qemu", `type`="qcow2"
          source file="/var/lib/libvirt/images/guest.qcow2"
          target dev="vda", bus="virtio"
        `interface` `type`="network":
          source network="default"
          mac address="52:54:00:12:34:56"
          model `type`="virtio"
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
    check d.xml == expected

  test "escaping in text content":
    let d = domain(`type`="qemu"):
      name: "a&b"
    check d.xml.contains("&amp;")

  test "$ operator":
    let d = domain(`type`="qemu"):
      name: "x"
    check $d == d.xml

  test "non-default on_poweroff is emitted":
    let d = domain(`type`="kvm"):
      name: "test"
      on_poweroff: "preserve"
    check d.xml.contains("<on_poweroff>preserve</on_poweroff>")

  test "default events are omitted":
    let d = domain(`type`="kvm"):
      name: "test"
    check "<on_poweroff>" notin d.xml
    check "<on_reboot>" notin d.xml
    check "<on_crash>" notin d.xml
