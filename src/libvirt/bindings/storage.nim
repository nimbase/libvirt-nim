# Nim bindings for libvirt.
# APIs for management of storage pools and volumes (libvirt-storage.h).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common

type
  virStoragePoolState* = enum
    VIR_STORAGE_POOL_INACTIVE = 0
    VIR_STORAGE_POOL_BUILDING = 1
    VIR_STORAGE_POOL_RUNNING = 2
    VIR_STORAGE_POOL_DEGRADED = 3
    VIR_STORAGE_POOL_INACCESSIBLE = 4

  virStoragePoolBuildFlags* = enum
    VIR_STORAGE_POOL_BUILD_NEW = 0
    VIR_STORAGE_POOL_BUILD_REPAIR = 1
    VIR_STORAGE_POOL_BUILD_RESIZE = 2
    VIR_STORAGE_POOL_BUILD_NO_OVERWRITE = 4
    VIR_STORAGE_POOL_BUILD_OVERWRITE = 8

  virStoragePoolDeleteFlags* = enum
    VIR_STORAGE_POOL_DELETE_NORMAL = 0
    VIR_STORAGE_POOL_DELETE_ZEROED = 1

  virStoragePoolCreateFlags* = enum
    VIR_STORAGE_POOL_CREATE_NORMAL = 0
    VIR_STORAGE_POOL_CREATE_WITH_BUILD = 1
    VIR_STORAGE_POOL_CREATE_WITH_BUILD_OVERWRITE = 2
    VIR_STORAGE_POOL_CREATE_WITH_BUILD_NO_OVERWRITE = 4

  virStoragePoolInfo* {.importc: "struct _virStoragePoolInfo", header: "<libvirt/libvirt.h>".} = object
    state*: cint
    capacity*: culonglong
    allocation*: culonglong
    available*: culonglong

  virStoragePoolInfoPtr* = ptr virStoragePoolInfo

  virStorageVolType* = enum
    VIR_STORAGE_VOL_FILE = 0
    VIR_STORAGE_VOL_BLOCK = 1
    VIR_STORAGE_VOL_DIR = 2
    VIR_STORAGE_VOL_NETWORK = 3
    VIR_STORAGE_VOL_NETDIR = 4
    VIR_STORAGE_VOL_PLOOP = 5

  virStorageVolCreateFlags* = enum
    VIR_STORAGE_VOL_CREATE_PREALLOC_METADATA = 1
    VIR_STORAGE_VOL_CREATE_REFLINK = 2
    VIR_STORAGE_VOL_CREATE_VALIDATE = 4

  virStorageVolDeleteFlags* = enum
    VIR_STORAGE_VOL_DELETE_NORMAL = 0
    VIR_STORAGE_VOL_DELETE_ZEROED = 1

  virStorageVolInfo* {.importc: "struct _virStorageVolInfo", header: "<libvirt/libvirt.h>".} = object
    `type`*: cint
    capacity*: culonglong
    allocation*: culonglong

  virStorageVolInfoPtr* = ptr virStorageVolInfo

{.push, importc, header: "<libvirt/libvirt.h>", dynlib: "libvirt." & ext.}

# Storage pools
proc virStoragePoolRef*(pool: virStoragePoolPtr): cint
proc virStoragePoolFree*(pool: virStoragePoolPtr): cint
proc virStoragePoolGetName*(pool: virStoragePoolPtr): cstring
proc virStoragePoolLookupByName*(conn: virConnectPtr, name: cstring): virStoragePoolPtr
proc virStoragePoolLookupByUUIDString*(conn: virConnectPtr, uuid: cstring): virStoragePoolPtr
proc virStoragePoolCreateXML*(conn: virConnectPtr, xmlDesc: cstring, flags: cuint): virStoragePoolPtr
proc virStoragePoolDefineXML*(conn: virConnectPtr, xmlDesc: cstring, flags: cuint): virStoragePoolPtr
proc virStoragePoolBuild*(pool: virStoragePoolPtr, flags: cuint): cint
proc virStoragePoolUndefine*(pool: virStoragePoolPtr): cint
proc virStoragePoolCreate*(pool: virStoragePoolPtr, flags: cuint): cint
proc virStoragePoolDestroy*(pool: virStoragePoolPtr): cint
proc virStoragePoolDelete*(pool: virStoragePoolPtr, flags: cuint): cint
proc virStoragePoolRefresh*(pool: virStoragePoolPtr, flags: cuint): cint
proc virStoragePoolGetInfo*(pool: virStoragePoolPtr, info: virStoragePoolInfoPtr): cint
proc virStoragePoolGetXMLDesc*(pool: virStoragePoolPtr, flags: cuint): cstring
proc virStoragePoolGetAutostart*(pool: virStoragePoolPtr, autostart: ptr cint): cint
proc virStoragePoolSetAutostart*(pool: virStoragePoolPtr, autostart: cint): cint
proc virConnectListAllStoragePools*(conn: virConnectPtr, pools: ptr virStoragePoolPtr, flags: cuint): cint
proc virStoragePoolListAllVolumes*(pool: virStoragePoolPtr, vols: ptr virStorageVolPtr, flags: cuint): cint

# Storage volumes
proc virStorageVolRef*(vol: virStorageVolPtr): cint
proc virStorageVolFree*(vol: virStorageVolPtr): cint
proc virStorageVolGetName*(vol: virStorageVolPtr): cstring
proc virStorageVolGetKey*(vol: virStorageVolPtr): cstring
proc virStorageVolGetPath*(vol: virStorageVolPtr): cstring
proc virStorageVolLookupByName*(pool: virStoragePoolPtr, name: cstring): virStorageVolPtr
proc virStorageVolCreateXML*(pool: virStoragePoolPtr, xmlDesc: cstring, flags: cuint): virStorageVolPtr
proc virStorageVolDelete*(vol: virStorageVolPtr, flags: cuint): cint
proc virStorageVolWipe*(vol: virStorageVolPtr, flags: cuint): cint
proc virStorageVolGetInfo*(vol: virStorageVolPtr, info: virStorageVolInfoPtr): cint
proc virStorageVolGetInfoFlags*(vol: virStorageVolPtr, info: virStorageVolInfoPtr, flags: cuint): cint
proc virStorageVolGetXMLDesc*(vol: virStorageVolPtr, flags: cuint): cstring
{.pop.}
