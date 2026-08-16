# Nim bindings for libvirt.
# Common opaque types shared by all binding modules.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

const ext* =
  when defined(linux):
    "so"
  elif defined(windows):
    "dll"
  else:
    "dylib"

type
  # Opaque pointer types
  virConnect* {.importc: "struct _virConnect", header: "<libvirt/libvirt.h>", incompleteStruct.} = object
  virDomain* {.importc: "struct _virDomain", header: "<libvirt/libvirt.h>", incompleteStruct.} = object
  virNetwork* {.importc: "struct _virNetwork", header: "<libvirt/libvirt.h>", incompleteStruct.} = object
  virStoragePool* {.importc: "struct _virStoragePool", header: "<libvirt/libvirt.h>", incompleteStruct.} = object
  virStorageVol* {.importc: "struct _virStorageVol", header: "<libvirt/libvirt.h>", incompleteStruct.} = object
  virStream* {.importc: "struct _virStream", header: "<libvirt/libvirt.h>", incompleteStruct.} = object

  virConnectPtr* = ptr virConnect
  virDomainPtr* = ptr virDomain
  virNetworkPtr* = ptr virNetwork
  virStoragePoolPtr* = ptr virStoragePool
  virStorageVolPtr* = ptr virStorageVol
  virStreamPtr* = ptr virStream

  virFreeCallback* = proc(opaque: pointer) {.cdecl.}

const
  VIR_TYPED_PARAM_FIELD_LENGTH* = 80
  VIR_SECURITY_LABEL_BUFLEN* = 4096 + 1

proc free*(p: pointer) {.importc: "free", header: "<stdlib.h>".}
