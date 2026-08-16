# Nim bindings for libvirt.
# Idiomatic, memory-safe wrapper around the thin bindings.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/tables
import ./bindings/common
import ./bindings/[host, domain, network, storage, stream, virterror]

type
  LibvirtError* = object of CatchableError
    code*: cint
    domain*: cint

proc lastError(): ref LibvirtError =
  let err = virGetLastError()
  let msg = if err != nil and err.message != nil: $err.message else: "unknown libvirt error"
  result = newException(LibvirtError, msg)
  if err != nil:
    result.code = err.code
    result.domain = err.domain

template check*(ret: cint) =
  ## Raises `LibvirtError` if `ret` signals a failure.
  if ret < 0:
    raise lastError()

proc checkPtr*[T](p: ptr T): ptr T =
  if p == nil:
    raise lastError()
  p

# ------------------------------------------------------------------
# Connection
# ------------------------------------------------------------------

type
  Connect* = ref ConnectObj
  ConnectObj* = object
    Handle*: virConnectPtr

proc `=destroy`(self: var ConnectObj) =
  if self.Handle != nil:
    discard virConnectClose(self.Handle)
    self.Handle = nil

proc openConnect*(uri = ""): Connect =
  ## Opens a new connection to the hypervisor driver named by `uri`.
  let c = if uri.len > 0: virConnectOpen(uri.cstring) else: virConnectOpen(nil)
  Connect(Handle: checkPtr(c))

proc openConnectReadOnly*(uri = ""): Connect =
  let c = if uri.len > 0: virConnectOpenReadOnly(uri.cstring) else: virConnectOpenReadOnly(nil)
  Connect(Handle: checkPtr(c))

proc close*(self: Connect) =
  if self.Handle != nil:
    discard virConnectClose(self.Handle)
    self.Handle = nil

proc isAlive*(self: Connect): bool =
  if self.Handle == nil: return false
  virConnectIsAlive(self.Handle) == 1

proc getType*(self: Connect): string =
  let t = virConnectGetType(self.Handle)
  if t == nil: raise lastError()
  $t

proc getVersion*(self: Connect): culong =
  var ver: culong
  check virConnectGetVersion(self.Handle, addr ver)
  ver

proc getLibVersion*(self: Connect): culong =
  var ver: culong
  check virConnectGetLibVersion(self.Handle, addr ver)
  ver

proc getHostname*(self: Connect): string =
  let h = virConnectGetHostname(self.Handle)
  if h == nil: raise lastError()
  result = $h
  free(h)

proc getCapabilities*(self: Connect): string =
  let c = virConnectGetCapabilities(self.Handle)
  if c == nil: raise lastError()
  result = $c
  free(c)

proc getNodeInfo*(self: Connect): virNodeInfo =
  var info: virNodeInfo
  check virNodeGetInfo(self.Handle, addr info)
  info

# ------------------------------------------------------------------
# Domains
# ------------------------------------------------------------------

type
  Domain* = ref DomainObj
  DomainObj* = object
    Handle*: virDomainPtr

proc `=destroy`(self: var DomainObj) =
  if self.Handle != nil:
    discard virDomainFree(self.Handle)
    self.Handle = nil

proc listAllDomains*(self: Connect, flags: cuint = 0): seq[Domain] =
  var domains: ptr virDomain = nil
  let n = virConnectListAllDomains(self.Handle, addr domains, flags)
  if n < 0: raise lastError()
  result = newSeq[Domain](n)
  let arr = cast[ptr UncheckedArray[virDomainPtr]](domains)
  for i in 0 ..< n:
    result[i] = Domain(Handle: arr[i])
  free(cast[pointer](domains))

proc lookupDomainByName*(self: Connect, name: string): Domain =
  Domain(Handle: checkPtr(virDomainLookupByName(self.Handle, name.cstring)))

proc lookupDomainByID*(self: Connect, id: cint): Domain =
  Domain(Handle: checkPtr(virDomainLookupByID(self.Handle, id)))

proc createDomainXML*(self: Connect, xml: string, flags: cuint = 0): Domain =
  ## Creates and starts a new transient domain from `xml`.
  Domain(Handle: checkPtr(virDomainCreateXML(self.Handle, xml.cstring, flags)))

proc defineDomainXML*(self: Connect, xml: string): Domain =
  ## Defines a persistent domain from `xml`.
  Domain(Handle: checkPtr(virDomainDefineXML(self.Handle, xml.cstring)))

proc name*(self: Domain): string =
  let n = virDomainGetName(self.Handle)
  if n == nil: raise lastError()
  $n

proc id*(self: Domain): cuint =
  virDomainGetID(self.Handle)

proc uuidString*(self: Domain): string =
  var buf: array[37, char]
  check virDomainGetUUIDString(self.Handle, cast[cstring](addr buf[0]))
  $cast[cstring](addr buf[0])

proc info*(self: Domain): virDomainInfo =
  var info: virDomainInfo
  check virDomainGetInfo(self.Handle, addr info)
  info

proc state*(self: Domain): tuple[state: virDomainState, reason: cint] =
  var s, r: cint
  check virDomainGetState(self.Handle, addr s, addr r, 0)
  (virDomainState(s), r)

proc xmlDesc*(self: Domain, flags: cuint = 0): string =
  let x = virDomainGetXMLDesc(self.Handle, flags)
  if x == nil: raise lastError()
  result = $x
  free(x)

proc isActive*(self: Domain): bool =
  virDomainIsActive(self.Handle) == 1

proc isPersistent*(self: Domain): bool =
  virDomainIsPersistent(self.Handle) == 1

proc autostart*(self: Domain): bool =
  var a: cint
  check virDomainGetAutostart(self.Handle, addr a)
  a == 1

proc setAutostart*(self: Domain, value: bool) =
  check virDomainSetAutostart(self.Handle, if value: 1 else: 0)

proc shutdown*(self: Domain, flags: cuint = 0) =
  check virDomainShutdownFlags(self.Handle, flags)

proc reboot*(self: Domain, flags: cuint = 0) =
  check virDomainReboot(self.Handle, flags)

proc destroy*(self: Domain, flags: cuint = 0) =
  check virDomainDestroyFlags(self.Handle, flags)

proc suspend*(self: Domain) =
  check virDomainSuspend(self.Handle)

proc resume*(self: Domain) =
  check virDomainResume(self.Handle)

proc create*(self: Domain) =
  check virDomainCreate(self.Handle)

proc undefine*(self: Domain) =
  check virDomainUndefine(self.Handle)

proc setMemory*(self: Domain, memory: culong) =
  check virDomainSetMemory(self.Handle, memory)

proc maxMemory*(self: Domain): culong =
  virDomainGetMaxMemory(self.Handle)

proc osType*(self: Domain): string =
  let t = virDomainGetOSType(self.Handle)
  if t == nil: raise lastError()
  result = $t
  free(t)

# ------------------------------------------------------------------
# Networks
# ------------------------------------------------------------------

type
  Network* = ref NetworkObj
  NetworkObj* = object
    Handle*: virNetworkPtr

proc `=destroy`(self: var NetworkObj) =
  if self.Handle != nil:
    discard virNetworkFree(self.Handle)
    self.Handle = nil

proc listAllNetworks*(self: Connect, flags: cuint = 0): seq[Network] =
  var nets: ptr virNetwork = nil
  let n = virConnectListAllNetworks(self.Handle, addr nets, flags)
  if n < 0: raise lastError()
  result = newSeq[Network](n)
  let arr = cast[ptr UncheckedArray[virNetworkPtr]](nets)
  for i in 0 ..< n:
    result[i] = Network(Handle: arr[i])
  free(cast[pointer](nets))

proc lookupNetworkByName*(self: Connect, name: string): Network =
  Network(Handle: checkPtr(virNetworkLookupByName(self.Handle, name.cstring)))

proc createNetworkXML*(self: Connect, xml: string): Network =
  Network(Handle: checkPtr(virNetworkCreateXML(self.Handle, xml.cstring)))

proc defineNetworkXML*(self: Connect, xml: string): Network =
  Network(Handle: checkPtr(virNetworkDefineXML(self.Handle, xml.cstring)))

proc name*(self: Network): string =
  let n = virNetworkGetName(self.Handle)
  if n == nil: raise lastError()
  $n

proc xmlDesc*(self: Network, flags: cuint = 0): string =
  let x = virNetworkGetXMLDesc(self.Handle, flags)
  if x == nil: raise lastError()
  result = $x
  free(x)

proc isActive*(self: Network): bool =
  virNetworkIsActive(self.Handle) == 1

proc isPersistent*(self: Network): bool =
  virNetworkIsPersistent(self.Handle) == 1

proc autostart*(self: Network): bool =
  var a: cint
  check virNetworkGetAutostart(self.Handle, addr a)
  a == 1

proc setAutostart*(self: Network, value: bool) =
  check virNetworkSetAutostart(self.Handle, if value: 1 else: 0)

proc create*(self: Network) =
  check virNetworkCreate(self.Handle)

proc destroy*(self: Network) =
  check virNetworkDestroy(self.Handle)

proc undefine*(self: Network) =
  check virNetworkUndefine(self.Handle)

# ------------------------------------------------------------------
# Storage
# ------------------------------------------------------------------

type
  StoragePool* = ref StoragePoolObj
  StoragePoolObj* = object
    Handle*: virStoragePoolPtr

  StorageVol* = ref StorageVolObj
  StorageVolObj* = object
    Handle*: virStorageVolPtr

proc `=destroy`(self: var StoragePoolObj) =
  if self.Handle != nil:
    discard virStoragePoolFree(self.Handle)
    self.Handle = nil

proc `=destroy`(self: var StorageVolObj) =
  if self.Handle != nil:
    discard virStorageVolFree(self.Handle)
    self.Handle = nil

proc listAllStoragePools*(self: Connect, flags: cuint = 0): seq[StoragePool] =
  var pools: ptr virStoragePool = nil
  let n = virConnectListAllStoragePools(self.Handle, addr pools, flags)
  if n < 0: raise lastError()
  result = newSeq[StoragePool](n)
  let arr = cast[ptr UncheckedArray[virStoragePoolPtr]](pools)
  for i in 0 ..< n:
    result[i] = StoragePool(Handle: arr[i])
  free(cast[pointer](pools))

proc lookupStoragePoolByName*(self: Connect, name: string): StoragePool =
  StoragePool(Handle: checkPtr(virStoragePoolLookupByName(self.Handle, name.cstring)))

proc createStoragePoolXML*(self: Connect, xml: string, flags: cuint = 0): StoragePool =
  StoragePool(Handle: checkPtr(virStoragePoolCreateXML(self.Handle, xml.cstring, flags)))

proc defineStoragePoolXML*(self: Connect, xml: string, flags: cuint = 0): StoragePool =
  StoragePool(Handle: checkPtr(virStoragePoolDefineXML(self.Handle, xml.cstring, flags)))

proc name*(self: StoragePool): string =
  let n = virStoragePoolGetName(self.Handle)
  if n == nil: raise lastError()
  $n

proc info*(self: StoragePool): virStoragePoolInfo =
  var info: virStoragePoolInfo
  check virStoragePoolGetInfo(self.Handle, addr info)
  info

proc xmlDesc*(self: StoragePool, flags: cuint = 0): string =
  let x = virStoragePoolGetXMLDesc(self.Handle, flags)
  if x == nil: raise lastError()
  result = $x
  free(x)

proc autostart*(self: StoragePool): bool =
  var a: cint
  check virStoragePoolGetAutostart(self.Handle, addr a)
  a == 1

proc setAutostart*(self: StoragePool, value: bool) =
  check virStoragePoolSetAutostart(self.Handle, if value: 1 else: 0)

proc build*(self: StoragePool, flags: cuint = 0) =
  check virStoragePoolBuild(self.Handle, flags)

proc create*(self: StoragePool, flags: cuint = 0) =
  check virStoragePoolCreate(self.Handle, flags)

proc destroy*(self: StoragePool) =
  check virStoragePoolDestroy(self.Handle)

proc undefine*(self: StoragePool) =
  check virStoragePoolUndefine(self.Handle)

proc listAllVolumes*(self: StoragePool, flags: cuint = 0): seq[StorageVol] =
  var vols: ptr virStorageVol = nil
  let n = virStoragePoolListAllVolumes(self.Handle, addr vols, flags)
  if n < 0: raise lastError()
  result = newSeq[StorageVol](n)
  let arr = cast[ptr UncheckedArray[virStorageVolPtr]](vols)
  for i in 0 ..< n:
    result[i] = StorageVol(Handle: arr[i])
  free(cast[pointer](vols))

proc lookupVolumeByName*(self: StoragePool, name: string): StorageVol =
  StorageVol(Handle: checkPtr(virStorageVolLookupByName(self.Handle, name.cstring)))

proc createVolumeXML*(self: StoragePool, xml: string, flags: cuint = 0): StorageVol =
  StorageVol(Handle: checkPtr(virStorageVolCreateXML(self.Handle, xml.cstring, flags)))

proc name*(self: StorageVol): string =
  let n = virStorageVolGetName(self.Handle)
  if n == nil: raise lastError()
  $n

proc key*(self: StorageVol): string =
  let k = virStorageVolGetKey(self.Handle)
  if k == nil: raise lastError()
  $k

proc path*(self: StorageVol): string =
  let p = virStorageVolGetPath(self.Handle)
  if p == nil: raise lastError()
  result = $p
  free(p)

proc info*(self: StorageVol): virStorageVolInfo =
  var info: virStorageVolInfo
  check virStorageVolGetInfo(self.Handle, addr info)
  info

proc xmlDesc*(self: StorageVol, flags: cuint = 0): string =
  let x = virStorageVolGetXMLDesc(self.Handle, flags)
  if x == nil: raise lastError()
  result = $x
  free(x)

proc delete*(self: StorageVol, flags: cuint = 0) =
  check virStorageVolDelete(self.Handle, flags)

# ------------------------------------------------------------------
# Streams
# ------------------------------------------------------------------

type
  Stream* = ref StreamObj
  StreamObj* = object
    Handle*: virStreamPtr

proc `=destroy`(self: var StreamObj) =
  if self.Handle != nil:
    discard virStreamFree(self.Handle)
    self.Handle = nil

proc newStream*(self: Connect, flags: cuint = 0): Stream =
  Stream(Handle: checkPtr(virStreamNew(self.Handle, flags)))

proc send*(self: Stream, data: string): cint =
  let n = virStreamSend(self.Handle, data.cstring, data.len.csize_t)
  if n < 0: raise lastError()
  n

proc recv*(self: Stream, size = 4096'u): string =
  var buf = newString(size)
  let n = virStreamRecv(self.Handle, cast[cstring](addr buf[0]), size)
  if n < 0: raise lastError()
  buf[0 ..< n]

proc finish*(self: Stream): cint =
  let n = virStreamFinish(self.Handle)
  if n < 0: raise lastError()
  n

proc abort*(self: Stream): cint =
  let n = virStreamAbort(self.Handle)
  if n < 0: raise lastError()
  n

# ------------------------------------------------------------------
# Events
# ------------------------------------------------------------------

type
  DomainEventCallback* = proc(conn: virConnectPtr, dom: virDomainPtr, event: cint, detail: cint) {.closure.}

  DomainEvent* = ref DomainEventObj
  DomainEventObj* = object
    conn*: Connect
    marker: pointer
    callbackID: cint

var registeredCallbacks: Table[pointer, DomainEventCallback]

proc `=destroy`(self: var DomainEventObj) =
  if self.marker != nil:
    discard virConnectDomainEventDeregisterAny(self.conn.Handle, self.callbackID)
    registeredCallbacks.del(self.marker)
    dealloc(self.marker)
    self.marker = nil

proc eventTrampoline(conn: virConnectPtr, dom: virDomainPtr, event: cint, detail: cint, opaque: pointer): cint {.cdecl.} =
  let cb = registeredCallbacks.getOrDefault(opaque)
  if cb != nil:
    cb(conn, dom, event, detail)
  result = 0

proc eventFreeCb(opaque: pointer) {.cdecl.} =
  if opaque != nil:
    registeredCallbacks.del(opaque)
    dealloc(opaque)

proc registerDomainEvent*(self: Connect, callback: DomainEventCallback, dom: virDomainPtr = nil): DomainEvent =
  ## Registers a lifecycle event callback. The returned `DomainEvent`
  ## keeps the callback alive until it is no longer referenced.
  let marker = alloc0(1)
  registeredCallbacks[marker] = callback
  let id = virConnectDomainEventRegisterAny(self.Handle, dom,
                                            VIR_DOMAIN_EVENT_ID_LIFECYCLE.cint,
                                            cast[virConnectDomainEventGenericCallback](eventTrampoline),
                                            marker, eventFreeCb)
  if id < 0:
    registeredCallbacks.del(marker)
    dealloc(marker)
    raise lastError()
  DomainEvent(conn: self, marker: marker, callbackID: id)

proc callbackID*(self: DomainEvent): cint =
  self.callbackID

proc deregister*(self: DomainEvent) =
  if self.marker != nil:
    discard virConnectDomainEventDeregisterAny(self.conn.Handle, self.callbackID)
    registeredCallbacks.del(self.marker)
    dealloc(self.marker)
    self.marker = nil
