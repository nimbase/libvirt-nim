# Nim bindings for libvirt.
# APIs for management of events (libvirt-event.h).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common

type
  virEventHandleType* = enum
    VIR_EVENT_HANDLE_READABLE = 1
    VIR_EVENT_HANDLE_WRITABLE = 2
    VIR_EVENT_HANDLE_ERROR = 4
    VIR_EVENT_HANDLE_HANGUP = 8

  virEventHandleCallback* = proc(watch: cint, fd: cint, events: cint, opaque: pointer) {.cdecl.}
  virEventTimeoutCallback* = proc(timer: cint, opaque: pointer) {.cdecl.}
  virEventAddHandleFunc* = proc(fd: cint, event: cint, cb: virEventHandleCallback, opaque: pointer, ff: virFreeCallback): cint {.cdecl.}
  virEventUpdateHandleFunc* = proc(watch: cint, event: cint) {.cdecl.}
  virEventRemoveHandleFunc* = proc(watch: cint): cint {.cdecl.}
  virEventAddTimeoutFunc* = proc(timeout: cint, cb: virEventTimeoutCallback, opaque: pointer, ff: virFreeCallback): cint {.cdecl.}
  virEventUpdateTimeoutFunc* = proc(timer: cint, timeout: cint) {.cdecl.}
  virEventRemoveTimeoutFunc* = proc(timer: cint): cint {.cdecl.}

{.push, importc, header: "<libvirt/libvirt.h>", dynlib: "libvirt." & ext.}
proc virEventRegisterImpl*(addHandle: virEventAddHandleFunc, updateHandle: virEventUpdateHandleFunc, removeHandle: virEventRemoveHandleFunc, addTimeout: virEventAddTimeoutFunc, updateTimeout: virEventUpdateTimeoutFunc, removeTimeout: virEventRemoveTimeoutFunc)
proc virEventRegisterDefaultImpl*(): cint
proc virEventRunDefaultImpl*(): cint
proc virEventAddHandle*(fd: cint, events: cint, cb: virEventHandleCallback, opaque: pointer, ff: virFreeCallback): cint
proc virEventUpdateHandle*(watch: cint, events: cint)
proc virEventRemoveHandle*(watch: cint): cint
proc virEventAddTimeout*(frequency: cint, cb: virEventTimeoutCallback, opaque: pointer, ff: virFreeCallback): cint
proc virEventUpdateTimeout*(timer: cint, frequency: cint)
proc virEventRemoveTimeout*(timer: cint): cint
{.pop.}
