# Nim bindings for libvirt.
# APIs for management of hosts and connections (libvirt-host.h).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common

type
  virNodeSuspendTarget* = enum
    VIR_NODE_SUSPEND_TARGET_MEM = 0
    VIR_NODE_SUSPEND_TARGET_DISK = 1
    VIR_NODE_SUSPEND_TARGET_HYBRID = 2

  virSecurityLabel* {.importc: "struct _virSecurityLabel", header: "<libvirt/libvirt.h>".} = object
    label*: array[VIR_SECURITY_LABEL_BUFLEN, char]
    enforcing*: cint

  virNodeInfo* {.importc: "struct _virNodeInfo", header: "<libvirt/libvirt.h>".} = object
    model*: array[32, char]
    memory*: culong
    cpus*: cint
    mhz*: cint
    nodes*: cint
    sockets*: cint
    cores*: cint
    threads*: cint

  virNodeInfoPtr* = ptr virNodeInfo

  virConnectCloseReason* = enum
    VIR_CONNECT_CLOSE_REASON_ERROR = 0
    VIR_CONNECT_CLOSE_REASON_EOF = 1
    VIR_CONNECT_CLOSE_REASON_KEEPALIVE = 2
    VIR_CONNECT_CLOSE_REASON_CLIENT = 3

  virConnectCloseFunc* = proc(conn: virConnectPtr, reason: cint, opaque: pointer) {.cdecl.}

{.push, importc, header: "<libvirt/libvirt.h>", dynlib: "libvirt." & ext.}
proc virGetVersion*(libVer: ptr culong, `type`: cstring, typeVer: ptr culong): cint

proc virConnectOpen*(name: cstring): virConnectPtr
proc virConnectOpenReadOnly*(name: cstring): virConnectPtr
proc virConnectClose*(conn: virConnectPtr): cint
proc virConnectRef*(conn: virConnectPtr): cint
proc virConnectGetType*(conn: virConnectPtr): cstring
proc virConnectGetVersion*(conn: virConnectPtr, hvVer: ptr culong): cint
proc virConnectGetLibVersion*(conn: virConnectPtr, libVer: ptr culong): cint
proc virConnectGetHostname*(conn: virConnectPtr): cstring
proc virConnectGetCapabilities*(conn: virConnectPtr): cstring
proc virConnectGetMaxVcpus*(conn: virConnectPtr, `type`: cstring): cint
proc virConnectIsAlive*(conn: virConnectPtr): cint
proc virConnectRegisterCloseCallback*(conn: virConnectPtr, cb: virConnectCloseFunc, opaque: pointer, freecb: virFreeCallback): cint
proc virConnectUnregisterCloseCallback*(conn: virConnectPtr, cb: virConnectCloseFunc): cint
proc virNodeGetInfo*(conn: virConnectPtr, info: virNodeInfoPtr): cint
proc virGetHostname*(): cstring
proc virFree*(p: pointer)
{.pop.}
