# Nim bindings for libvirt.
# APIs for management of data streams (libvirt-stream.h).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common

type
  virStreamEventType* = enum
    VIR_STREAM_EVENT_READABLE = 1
    VIR_STREAM_EVENT_WRITABLE = 2
    VIR_STREAM_EVENT_ERROR = 4
    VIR_STREAM_EVENT_HANGUP = 8

  virStreamEventCallback* = proc(st: virStreamPtr, events: cint, opaque: pointer) {.cdecl.}
  virStreamSinkFunc* = proc(st: virStreamPtr, data: cstring, nbytes: csize_t, opaque: pointer): cint {.cdecl.}
  virStreamSourceFunc* = proc(st: virStreamPtr, data: cstring, nbytes: csize_t, opaque: pointer): cint {.cdecl.}

const
  VIR_STREAM_NONBLOCK* = 1 shl 0

{.push, importc, header: "<libvirt/libvirt.h>", dynlib: "libvirt." & ext.}
proc virStreamNew*(conn: virConnectPtr, flags: cuint): virStreamPtr
proc virStreamRef*(st: virStreamPtr): cint
proc virStreamFree*(st: virStreamPtr): cint
proc virStreamSend*(st: virStreamPtr, data: cstring, nbytes: csize_t): cint
proc virStreamSendHuge*(st: virStreamPtr, data: cstring, nbytes: csize_t): clonglong
proc virStreamRecv*(st: virStreamPtr, data: cstring, nbytes: csize_t): cint
proc virStreamRecvHuge*(st: virStreamPtr, data: cstring, nbytes: csize_t): clonglong
proc virStreamFinish*(st: virStreamPtr): cint
proc virStreamAbort*(st: virStreamPtr): cint
proc virStreamEventAddCallback*(st: virStreamPtr, events: cint, cb: virStreamEventCallback, opaque: pointer, ff: virFreeCallback): cint
proc virStreamEventUpdateCallback*(st: virStreamPtr, events: cint): cint
proc virStreamEventRemoveCallback*(st: virStreamPtr): cint
{.pop.}
