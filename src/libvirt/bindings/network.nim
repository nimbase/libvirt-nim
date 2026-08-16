# Nim bindings for libvirt.
# APIs for management of networks (libvirt-network.h).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common

type
  virNetworkXMLFlags* = enum
    VIR_NETWORK_XML_INACTIVE = 1

  virNetworkCreateFlags* = enum
    VIR_NETWORK_CREATE_VALIDATE = 1

  virConnectListAllNetworksFlags* = enum
    VIR_CONNECT_LIST_NETWORKS_INACTIVE = 1
    VIR_CONNECT_LIST_NETWORKS_ACTIVE = 2
    VIR_CONNECT_LIST_NETWORKS_PERSISTENT = 4
    VIR_CONNECT_LIST_NETWORKS_TRANSIENT = 8
    VIR_CONNECT_LIST_NETWORKS_AUTOSTART = 16
    VIR_CONNECT_LIST_NETWORKS_NO_AUTOSTART = 32

{.push, importc, header: "<libvirt/libvirt.h>", dynlib: "libvirt." & ext.}
proc virNetworkRef*(network: virNetworkPtr): cint
proc virNetworkFree*(network: virNetworkPtr): cint
proc virNetworkGetName*(network: virNetworkPtr): cstring
proc virNetworkGetConnect*(network: virNetworkPtr): virConnectPtr
proc virNetworkLookupByName*(conn: virConnectPtr, name: cstring): virNetworkPtr
proc virNetworkLookupByUUIDString*(conn: virConnectPtr, uuid: cstring): virNetworkPtr

proc virNetworkCreateXML*(conn: virConnectPtr, xmlDesc: cstring): virNetworkPtr
proc virNetworkCreateXMLFlags*(conn: virConnectPtr, xmlDesc: cstring, flags: cuint): virNetworkPtr
proc virNetworkDefineXML*(conn: virConnectPtr, xmlDesc: cstring): virNetworkPtr
proc virNetworkDefineXMLFlags*(conn: virConnectPtr, xmlDesc: cstring, flags: cuint): virNetworkPtr
proc virNetworkCreate*(network: virNetworkPtr): cint
proc virNetworkDestroy*(network: virNetworkPtr): cint
proc virNetworkUndefine*(network: virNetworkPtr): cint

proc virNetworkGetXMLDesc*(network: virNetworkPtr, flags: cuint): cstring
proc virNetworkGetBridgeName*(network: virNetworkPtr): cstring
proc virNetworkGetAutostart*(network: virNetworkPtr, autostart: ptr cint): cint
proc virNetworkSetAutostart*(network: virNetworkPtr, autostart: cint): cint
proc virNetworkIsActive*(net: virNetworkPtr): cint
proc virNetworkIsPersistent*(net: virNetworkPtr): cint

proc virConnectListAllNetworks*(conn: virConnectPtr, nets: ptr virNetworkPtr, flags: cuint): cint
{.pop.}
