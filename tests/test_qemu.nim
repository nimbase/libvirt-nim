# Integration tests for libvirt Nim bindings against a real QEMU
# backend (qemu:///session).
#
# These tests are skipped unless LIBVIRT_TEST_QEMU=1 is set and a
# QEMU emulator is available. Because the macOS libvirt driver probes
# QEMU with the hvf accelerator (which aborts on hosts without
# Hypervisor.framework), the domain XML uses a small wrapper
# (tests/qemu-tcg.sh) that forces software emulation (TCG).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/[unittest, strutils, os, osproc]
import ../src/libvirt

const testUuid = "12345678-1234-1234-1234-123456789abc"
const domainName = "libvirt-nim-qtest"

proc wrapperPath(): string =
  currentSourcePath().parentDir / "qemu-tcg.sh"

proc qemuSystemPath(): string =
  "/opt/local/bin/qemu-system-x86_64"

proc diskImagePath(): string =
  getTempDir() / "libvirt-nim-qtest.img"

proc domainXml(emulator: string): string =
  """<domain type='qemu'>
  <name>$NAME</name>
  <uuid>$UUID</uuid>
  <memory unit='KiB'>131072</memory>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
    <boot dev='hd'/>
  </os>
  <vcpu placement='static'>1</vcpu>
  <devices>
    <emulator>$EMU</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='raw'/>
      <source file='$DISK'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <serial type='pty'/>
    <console type='pty'/>
  </devices>
</domain>""".replace("$NAME", domainName)
      .replace("$UUID", testUuid)
      .replace("$EMU", emulator)
      .replace("$DISK", diskImagePath())

proc qemuAvailable(): bool =
  fileExists(wrapperPath()) and fileExists(qemuSystemPath()) and
    (getEnv("LIBVIRT_TEST_QEMU") == "1")

proc createDiskImage(): bool =
  let rc = execCmd("qemu-img create -f raw " & diskImagePath() & " 1M")
  rc == 0

suite "libvirt qemu integration":
  test "connect to qemu:///session":
    if not qemuAvailable():
      echo "skipping (LIBVIRT_TEST_QEMU=1 not set or QEMU unavailable)"
    else:
      let conn = openConnect("qemu:///session")
      check conn.isAlive
      check conn.getType.toLowerAscii.contains("qemu")
      conn.close

  test "define, start, inspect, suspend, resume, destroy, undefine":
    if not qemuAvailable():
      echo "skipping (LIBVIRT_TEST_QEMU=1 not set or QEMU unavailable)"
    else:
      check createDiskImage()
      defer: removeFile(diskImagePath())

      let conn = openConnect("qemu:///session")
      let xml = domainXml(wrapperPath())

      var dom: Domain
      try:
        dom = conn.defineDomainXML(xml)
      except LibvirtError as e:
        echo "define failed: ", e.msg
        raise
      check dom.name == domainName
      check dom.isPersistent
      check not dom.isActive

      dom.create
      check dom.isActive
      var (state, _) = dom.state
      check state == VIR_DOMAIN_RUNNING

      let xmlDesc = dom.xmlDesc
      check xmlDesc.contains("<domain")

      dom.suspend
      (state, _) = dom.state
      check state == VIR_DOMAIN_PAUSED

      dom.resume
      (state, _) = dom.state
      check state == VIR_DOMAIN_RUNNING

      dom.destroy
      check not dom.isActive
      dom.undefine