# Tests for libvirt Nim bindings.
#
# Uses the built-in test driver (test:///default) which requires no
# hypervisor or daemon, so these tests run anywhere libvirt is installed.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/[unittest, strutils]
import ../src/libvirt

suite "libvirt bindings":
  test "open connection (test:///default)":
    let conn = openConnect("test:///default")
    check conn.isAlive
    check conn.getType.toLowerAscii == "test"
    check conn.getLibVersion > 0

  test "close connection":
    let conn = openConnect("test:///default")
    conn.close
    check not conn.isAlive

  test "node info":
    let conn = openConnect("test:///default")
    let info = conn.getNodeInfo
    check info.cpus > 0
    check info.memory > 0

  test "list all domains":
    let conn = openConnect("test:///default")
    let domains = conn.listAllDomains
    check domains.len >= 1

  test "domain properties":
    let conn = openConnect("test:///default")
    let domains = conn.listAllDomains
    let d = domains[0]
    check d.name.len > 0
    check d.uuidString.len == 36
    check d.isPersistent
    check d.maxMemory > 0
    check d.osType.len > 0

  test "domain xml desc":
    let conn = openConnect("test:///default")
    let domains = conn.listAllDomains
    let xml = domains[0].xmlDesc
    check xml.len > 0
    check xml.contains("<domain")

  test "lookup domain by name":
    let conn = openConnect("test:///default")
    let d = conn.lookupDomainByName("test")
    check d.name == "test"

  test "domain not found raises LibvirtError":
    let conn = openConnect("test:///default")
    expect LibvirtError:
      discard conn.lookupDomainByName("does-not-exist")

  test "invalid uri raises LibvirtError":
    expect LibvirtError:
      discard openConnect("bogus:///uri")

  test "list all networks":
    let conn = openConnect("test:///default")
    let nets = conn.listAllNetworks
    check nets.len >= 1

  test "list all storage pools":
    let conn = openConnect("test:///default")
    let pools = conn.listAllStoragePools
    check pools.len >= 1

  test "virGetVersion":
    var libVer: culong
    var typeVer: culong
    check virGetVersion(addr libVer, nil, addr typeVer) == 0
    check libVer > 0

  test "register domain event":
    discard virEventRegisterDefaultImpl()
    let conn = openConnect("test:///default")
    let cb: DomainEventCallback = proc(conn: virConnectPtr, dom: virDomainPtr, event: cint, detail: cint) {.closure.} =
      discard
    let ev = conn.registerDomainEvent(cb)
    check ev.callbackID >= 0
    ev.deregister
