# Nim bindings for libvirt.
# APIs for management of domains (libvirt-domain.h).
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./common

type
  virDomainState* = enum
    VIR_DOMAIN_NOSTATE = 0
    VIR_DOMAIN_RUNNING = 1
    VIR_DOMAIN_BLOCKED = 2
    VIR_DOMAIN_PAUSED = 3
    VIR_DOMAIN_SHUTDOWN = 4
    VIR_DOMAIN_SHUTOFF = 5
    VIR_DOMAIN_CRASHED = 6
    VIR_DOMAIN_PMSUSPENDED = 7

  virDomainInfo* {.importc: "struct _virDomainInfo", header: "<libvirt/libvirt.h>".} = object
    state*: cuchar
    maxMem*: culong
    memory*: culong
    nrVirtCpu*: cushort
    cpuTime*: culonglong

  virDomainInfoPtr* = ptr virDomainInfo

  virDomainCreateFlags* = enum
    VIR_DOMAIN_NONE = 0
    VIR_DOMAIN_START_PAUSED = 1
    VIR_DOMAIN_START_AUTODESTROY = 2
    VIR_DOMAIN_START_BYPASS_CACHE = 4
    VIR_DOMAIN_START_FORCE_BOOT = 8
    VIR_DOMAIN_START_VALIDATE = 16
    VIR_DOMAIN_START_RESET_NVRAM = 32

  virDomainShutdownFlagValues* = enum
    VIR_DOMAIN_SHUTDOWN_DEFAULT = 0
    VIR_DOMAIN_SHUTDOWN_ACPI_POWER_BTN = 1
    VIR_DOMAIN_SHUTDOWN_GUEST_AGENT = 2
    VIR_DOMAIN_SHUTDOWN_INITCTL = 4
    VIR_DOMAIN_SHUTDOWN_SIGNAL = 8
    VIR_DOMAIN_SHUTDOWN_PARAVIRT = 16

  virDomainRebootFlagValues* = enum
    VIR_DOMAIN_REBOOT_DEFAULT = 0
    VIR_DOMAIN_REBOOT_ACPI_POWER_BTN = 1
    VIR_DOMAIN_REBOOT_GUEST_AGENT = 2
    VIR_DOMAIN_REBOOT_INITCTL = 4
    VIR_DOMAIN_REBOOT_SIGNAL = 8
    VIR_DOMAIN_REBOOT_PARAVIRT = 16

  virDomainDestroyFlagsValues* = enum
    VIR_DOMAIN_DESTROY_DEFAULT = 0
    VIR_DOMAIN_DESTROY_GRACEFUL = 1
    VIR_DOMAIN_DESTROY_REMOVE_LOGS = 2

  virDomainUndefineFlagsValues* = enum
    VIR_DOMAIN_UNDEFINE_NONE = 0
    VIR_DOMAIN_UNDEFINE_MANAGED_SAVE = 1
    VIR_DOMAIN_UNDEFINE_SNAPSHOTS_METADATA = 2
    VIR_DOMAIN_UNDEFINE_NVRAM = 4
    VIR_DOMAIN_UNDEFINE_KEEP_NVRAM = 8
    VIR_DOMAIN_UNDEFINE_CHECKPOINTS_METADATA = 16

  virDomainXMLFlags* = enum
    VIR_DOMAIN_XML_NONE = 0
    VIR_DOMAIN_XML_SECURE = 1
    VIR_DOMAIN_XML_INACTIVE = 2
    VIR_DOMAIN_XML_UPDATE_CPU = 4
    VIR_DOMAIN_XML_MIGRATABLE = 8

  virDomainModificationImpact* = enum
    VIR_DOMAIN_AFFECT_CURRENT = 0
    VIR_DOMAIN_AFFECT_LIVE = 1
    VIR_DOMAIN_AFFECT_CONFIG = 2

  virConnectListAllDomainsFlags* = enum
    VIR_CONNECT_LIST_DOMAINS_ACTIVE = 1
    VIR_CONNECT_LIST_DOMAINS_INACTIVE = 2
    VIR_CONNECT_LIST_DOMAINS_PERSISTENT = 4
    VIR_CONNECT_LIST_DOMAINS_TRANSIENT = 8
    VIR_CONNECT_LIST_DOMAINS_RUNNING = 16
    VIR_CONNECT_LIST_DOMAINS_PAUSED = 32
    VIR_CONNECT_LIST_DOMAINS_SHUTOFF = 64
    VIR_CONNECT_LIST_DOMAINS_OTHER = 128
    VIR_CONNECT_LIST_DOMAINS_MANAGEDSAVE = 256
    VIR_CONNECT_LIST_DOMAINS_NO_MANAGEDSAVE = 512
    VIR_CONNECT_LIST_DOMAINS_AUTOSTART = 1024
    VIR_CONNECT_LIST_DOMAINS_NO_AUTOSTART = 2048
    VIR_CONNECT_LIST_DOMAINS_HAS_SNAPSHOT = 4096
    VIR_CONNECT_LIST_DOMAINS_NO_SNAPSHOT = 8192
    VIR_CONNECT_LIST_DOMAINS_HAS_CHECKPOINT = 16384
    VIR_CONNECT_LIST_DOMAINS_NO_CHECKPOINT = 32768

  virDomainEventLifecycle* = enum
    VIR_DOMAIN_EVENT_DEFINED = 0
    VIR_DOMAIN_EVENT_UNDEFINED = 1
    VIR_DOMAIN_EVENT_STARTED = 2
    VIR_DOMAIN_EVENT_SUSPENDED = 3
    VIR_DOMAIN_EVENT_RESUMED = 4
    VIR_DOMAIN_EVENT_STOPPED = 5
    VIR_DOMAIN_EVENT_SHUTDOWN = 6
    VIR_DOMAIN_EVENT_PMSUSPENDED = 7
    VIR_DOMAIN_EVENT_CRASHED = 8

  virDomainEventID* = enum
    VIR_DOMAIN_EVENT_ID_LIFECYCLE = 0
    VIR_DOMAIN_EVENT_ID_REBOOT = 1
    VIR_DOMAIN_EVENT_ID_RTC_CHANGE = 2
    VIR_DOMAIN_EVENT_ID_WATCHDOG = 3
    VIR_DOMAIN_EVENT_ID_IO_ERROR = 4
    VIR_DOMAIN_EVENT_ID_GRAPHICS = 5
    VIR_DOMAIN_EVENT_ID_IO_ERROR_REASON = 6
    VIR_DOMAIN_EVENT_ID_CONTROL_ERROR = 7
    VIR_DOMAIN_EVENT_ID_BLOCK_JOB = 8
    VIR_DOMAIN_EVENT_ID_DISK_CHANGE = 9
    VIR_DOMAIN_EVENT_ID_TRAY_CHANGE = 10
    VIR_DOMAIN_EVENT_ID_PMWAKEUP = 11
    VIR_DOMAIN_EVENT_ID_PMSUSPEND = 12
    VIR_DOMAIN_EVENT_ID_BALLOON_CHANGE = 13
    VIR_DOMAIN_EVENT_ID_PMSUSPEND_DISK = 14
    VIR_DOMAIN_EVENT_ID_DEVICE_REMOVED = 15
    VIR_DOMAIN_EVENT_ID_BLOCK_JOB_2 = 16
    VIR_DOMAIN_EVENT_ID_TUNABLE = 17
    VIR_DOMAIN_EVENT_ID_AGENT_LIFECYCLE = 18
    VIR_DOMAIN_EVENT_ID_DEVICE_ADDED = 19
    VIR_DOMAIN_EVENT_ID_MIGRATION_ITERATION = 20
    VIR_DOMAIN_EVENT_ID_JOB_COMPLETED = 21
    VIR_DOMAIN_EVENT_ID_DEVICE_REMOVAL_FAILED = 22
    VIR_DOMAIN_EVENT_ID_METADATA_CHANGE = 23
    VIR_DOMAIN_EVENT_ID_BLOCK_THRESHOLD = 24
    VIR_DOMAIN_EVENT_ID_MEMORY_FAILURE = 25
    VIR_DOMAIN_EVENT_ID_MEMORY_DEVICE_SIZE_CHANGE = 26
    VIR_DOMAIN_EVENT_ID_NIC_MAC_CHANGE = 27

  virDomainConsoleFlags* = enum
    VIR_DOMAIN_CONSOLE_FORCE = 1
    VIR_DOMAIN_CONSOLE_SAFE = 2

  virConnectDomainEventGenericCallback* = proc(conn: virConnectPtr, dom: virDomainPtr, opaque: pointer) {.cdecl.}
  virConnectDomainEventCallback* = proc(conn: virConnectPtr, dom: virDomainPtr, event: cint, detail: cint, opaque: pointer): cint {.cdecl.}

{.push, importc, header: "<libvirt/libvirt.h>", dynlib: "libvirt." & ext.}
proc virDomainRef*(domain: virDomainPtr): cint
proc virDomainFree*(domain: virDomainPtr): cint
proc virDomainGetName*(domain: virDomainPtr): cstring
proc virDomainGetID*(domain: virDomainPtr): cuint
proc virDomainGetUUID*(domain: virDomainPtr, uuid: ptr cuchar): cint
proc virDomainGetUUIDString*(domain: virDomainPtr, buf: cstring): cint
proc virDomainLookupByID*(conn: virConnectPtr, id: cint): virDomainPtr
proc virDomainLookupByName*(conn: virConnectPtr, name: cstring): virDomainPtr
proc virDomainLookupByUUID*(conn: virConnectPtr, uuid: ptr cuchar): virDomainPtr
proc virDomainLookupByUUIDString*(conn: virConnectPtr, uuidstr: cstring): virDomainPtr

proc virDomainCreate*(domain: virDomainPtr): cint
proc virDomainCreateWithFlags*(domain: virDomainPtr, flags: cuint): cint
proc virDomainCreateXML*(conn: virConnectPtr, xmlDesc: cstring, flags: cuint): virDomainPtr
proc virDomainDefineXML*(conn: virConnectPtr, xml: cstring): virDomainPtr
proc virDomainUndefine*(domain: virDomainPtr): cint
proc virDomainUndefineFlags*(domain: virDomainPtr, flags: cuint): cint
proc virDomainShutdown*(domain: virDomainPtr): cint
proc virDomainShutdownFlags*(domain: virDomainPtr, flags: cuint): cint
proc virDomainReboot*(domain: virDomainPtr, flags: cuint): cint
proc virDomainDestroy*(domain: virDomainPtr): cint
proc virDomainDestroyFlags*(domain: virDomainPtr, flags: cuint): cint
proc virDomainSuspend*(domain: virDomainPtr): cint
proc virDomainResume*(domain: virDomainPtr): cint
proc virDomainGetInfo*(domain: virDomainPtr, info: virDomainInfoPtr): cint
proc virDomainGetState*(domain: virDomainPtr, state: ptr cint, reason: ptr cint, flags: cuint): cint
proc virDomainGetXMLDesc*(domain: virDomainPtr, flags: cuint): cstring
proc virDomainIsActive*(dom: virDomainPtr): cint
proc virDomainIsPersistent*(dom: virDomainPtr): cint
proc virDomainGetAutostart*(domain: virDomainPtr, autostart: ptr cint): cint
proc virDomainSetAutostart*(domain: virDomainPtr, autostart: cint): cint
proc virDomainSetMemory*(domain: virDomainPtr, memory: culong): cint
proc virDomainGetMaxMemory*(domain: virDomainPtr): culong
proc virDomainGetOSType*(domain: virDomainPtr): cstring

proc virConnectListAllDomains*(conn: virConnectPtr, domains: ptr virDomainPtr, flags: cuint): cint

proc virDomainOpenConsole*(domain: virDomainPtr, devname: cstring, st: virStreamPtr, flags: cuint): cint

proc virConnectDomainEventRegisterAny*(conn: virConnectPtr, dom: virDomainPtr, eventID: cint, cb: virConnectDomainEventGenericCallback, opaque: pointer, freecb: virFreeCallback): cint
proc virConnectDomainEventDeregisterAny*(conn: virConnectPtr, callbackID: cint): cint
proc virConnectDomainEventRegister*(conn: virConnectPtr, cb: virConnectDomainEventCallback, opaque: pointer, freecb: virFreeCallback): cint
proc virConnectDomainEventDeregister*(conn: virConnectPtr, cb: virConnectDomainEventCallback): cint
{.pop.}
