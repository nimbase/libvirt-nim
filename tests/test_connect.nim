# Tests for libvirt Nim bindings.
#
# Uses the built-in test driver (test:///default) which requires no
# hypervisor or daemon, so these tests run anywhere libvirt is installed.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/[unittest, strutils, random]
import ../src/libvirt

randomize()

const
  testDomainXml = """
<domain type='test'>
  <name>$NAME</name>
  <uuid>$UUID</uuid>
  <memory unit='KiB'>131072</memory>
  <currentMemory unit='KiB'>131072</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='i686'>hvm</type>
    <boot dev='hd'/>
  </os>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <disk type='file' device='disk'>
      <source file='/guest/diskimage1'/>
      <target dev='vda' bus='virtio'/>
    </disk>
  </devices>
</domain>"""

  testNetworkXml = """
<network>
  <name>$NAME</name>
  <bridge name='virbr$BRIDGE'/>
</network>"""

  testPoolXml = """
<pool type='dir'>
  <name>$NAME</name>
  <target><path>/tmp/$NAME</path></target>
</pool>"""

  testVolXml = """
<volume>
  <name>$NAME</name>
  <capacity unit='KiB'>1024</capacity>
</volume>"""

proc fill(xml, name: string, uuid = ""): string =
  result = xml.replace("$NAME", name)
  if uuid.len > 0:
    result = result.replace("$UUID", uuid)

proc randomUuid(): string =
  var s = newSeq[string](16)
  for i in 0 ..< 16:
    s[i] = toHex(rand(255), 2)
  result = s[0] & s[1] & s[2] & s[3] & "-" &
           s[4] & s[5] & "-" & s[6] & s[7] & "-" &
           s[8] & s[9] & "-" & s[10] & s[11] & s[12] & s[13] & s[14] & s[15]

proc randName(prefix: string): string =
  prefix & "-" & $rand(100000)

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

  test "LibvirtError carries code and domain":
    let conn = openConnect("test:///default")
    try:
      discard conn.lookupDomainByName("does-not-exist")
      check false
    except LibvirtError as e:
      check e.msg.len > 0
      check e.code != 0

  test "virGetLastErrorMessage is populated after a failure":
    let conn = openConnect("test:///default")
    try:
      discard conn.lookupDomainByName("does-not-exist")
      check false
    except LibvirtError:
      discard
    let msg = $virGetLastErrorMessage()
    check msg.len > 0

  test "hostname and capabilities":
    let conn = openConnect("test:///default")
    check conn.getHostname.len > 0
    let caps = conn.getCapabilities
    check caps.contains("<capabilities")
    check caps.contains("<guest")

  test "virGetVersion":
    var libVer: culong
    var typeVer: culong
    check virGetVersion(addr libVer, nil, addr typeVer) == 0
    check libVer > 0

  test "list all networks":
    let conn = openConnect("test:///default")
    let nets = conn.listAllNetworks
    check nets.len >= 1

  test "list all storage pools":
    let conn = openConnect("test:///default")
    let pools = conn.listAllStoragePools
    check pools.len >= 1

  test "define and undefine a domain":
    let conn = openConnect("test:///default")
    let name = randName("defdom")
    let d = conn.defineDomainXML(fill(testDomainXml, name, randomUuid()))
    check d.name == name
    check d.isPersistent
    check not d.isActive
    d.undefine

  test "create transient domain then destroy":
    let conn = openConnect("test:///default")
    let name = randName("transdom")
    let d = conn.createDomainXML(fill(testDomainXml, name, randomUuid()))
    check d.isActive
    let (state, reason) = d.state
    check state == VIR_DOMAIN_RUNNING
    d.destroy

  test "define, start, suspend, resume, shutdown, undefine":
    let conn = openConnect("test:///default")
    let name = randName("lifecycle")
    let d = conn.defineDomainXML(fill(testDomainXml, name, randomUuid()))
    d.create
    check d.isActive
    d.suspend
    var (state, _) = d.state
    check state == VIR_DOMAIN_PAUSED
    d.resume
    (state, _) = d.state
    check state == VIR_DOMAIN_RUNNING
    d.shutdown
    check d.state.state in [VIR_DOMAIN_SHUTDOWN, VIR_DOMAIN_SHUTOFF]
    d.undefine

  test "domain autostart get/set":
    let conn = openConnect("test:///default")
    let name = randName("autostart")
    let d = conn.defineDomainXML(fill(testDomainXml, name, randomUuid()))
    let before = d.autostart
    d.setAutostart(not before)
    check d.autostart == (not before)
    d.undefine

  test "domain lookup by id":
    let conn = openConnect("test:///default")
    let domains = conn.listAllDomains
    let d = conn.lookupDomainByID(domains[0].id.cint)
    check d.name == domains[0].name

  test "create and destroy a network":
    let conn = openConnect("test:///default")
    let name = randName("net")
    let n = conn.createNetworkXML(fill(testNetworkXml, name, "").replace("$BRIDGE", $rand(100)))
    check n.isActive
    check not n.isPersistent
    n.destroy

  test "define, start, destroy, undefine a network":
    let conn = openConnect("test:///default")
    let name = randName("netpersist")
    let n = conn.defineNetworkXML(fill(testNetworkXml, name, "").replace("$BRIDGE", $rand(100)))
    check not n.isActive
    check n.isPersistent
    n.create
    check n.isActive
    n.destroy
    n.undefine

  test "storage pool and volume lifecycle":
    let conn = openConnect("test:///default")
    let poolName = randName("pool")
    let p = conn.defineStoragePoolXML(fill(testPoolXml, poolName))
    p.build
    p.create
    check p.info.state == VIR_STORAGE_POOL_RUNNING.cint

    let volName = randName("vol")
    let v = p.createVolumeXML(fill(testVolXml, volName))
    check v.name == volName
    check v.path.len > 0
    check v.info.capacity == 1024'u64 * 1024
    v.delete

    p.destroy
    p.undefine

  test "lookup storage volume by name":
    let conn = openConnect("test:///default")
    let pools = conn.listAllStoragePools
    let p = pools[0]
    let volName = randName("vol")
    let v = p.createVolumeXML(fill(testVolXml, volName))
    let found = p.lookupVolumeByName(volName)
    check found.name == volName
    v.delete

  test "domain lifecycle event fires on create":
    discard virEventRegisterDefaultImpl()
    let conn = openConnect("test:///default")
    var firedEvents: seq[cint] = @[]
    let cb: DomainEventCallback = proc(conn: virConnectPtr, dom: virDomainPtr, event: cint, detail: cint) {.closure.} =
      firedEvents.add(event)
    let ev = conn.registerDomainEvent(cb)
    check ev.callbackID >= 0

    let name = randName("evt")
    var d: Domain
    try:
      d = conn.createDomainXML(fill(testDomainXml, name, randomUuid()))
    except LibvirtError:
      discard
    var loops = 0
    while firedEvents.len == 0 and loops < 100:
      discard virEventRunDefaultImpl()
      inc loops
    check VIR_DOMAIN_EVENT_STARTED.cint in firedEvents
    if d != nil:
      d.destroy
    ev.deregister

  test "register domain event":
    discard virEventRegisterDefaultImpl()
    let conn = openConnect("test:///default")
    let cb: DomainEventCallback = proc(conn: virConnectPtr, dom: virDomainPtr, event: cint, detail: cint) {.closure.} =
      discard
    let ev = conn.registerDomainEvent(cb)
    check ev.callbackID >= 0
    ev.deregister