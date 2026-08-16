<p align="center">
  Nim bindings for <a href="https://libvirt.org">libvirt</a><br>
</p>

<p align="center">
  <code>nimble install libvirt</code>
</p>

<p align="center">
  <a href="https://nimbase.github.io/libvirt-nim/">API reference</a><br>
  <img src="https://github.com/nimbase/libvirt-nim/workflows/test/badge.svg" alt="Github Actions">  <img src="https://github.com/nimbase/libvirt-nim/workflows/docs/badge.svg" alt="Github Actions">
</p>

Curated bindings for the libvirt virtualization API. The package
is split into a thin, 1:1 core layer over the libvirt C API and an idiomatic
Nim wrapper layer that manages resources for you.

## Features

- Curated bindings for libvirt (thin `bindings/` layer, styled
  after libevent-nim) plus a memory-safe idiomatic layer (`api.nim`)
- RAII-style resource management: `Connect`, `Domain`, `Network`,
  `StoragePool`, `StorageVol` and `Stream` are `ref` objects that close or
  free their underlying libvirt handles (and returned C strings) when they
  go out of scope
- `LibvirtError` exception carrying the libvirt error `code` and `domain`
- Hypervisor connections: open / read-only open / close, alive check,
  hostname, versions, capabilities XML and node info
- Domain management: define, create (transient), start, suspend, resume,
  shutdown, reboot, destroy, undefine, autostart, lookup by name/ID,
  state, info and XML description
- Network and storage management: pools and volumes with full lifecycle
  (define, build, create, destroy, undefine, delete)
- Domain lifecycle event registration with an idiomatic callback API
- Streams support (`send`/`recv`/`finish`/`abort`)
- Tested against the built-in `test:///default` driver, so the suite runs
  anywhere libvirt is installed without a hypervisor or daemon

## Requirements

- A system-installed libvirt C library (development headers). On macOS via
  MacPorts: `sudo port install libvirt`; on Homebrew: `brew install libvirt`
- Nim >= 2.0.0

The build links against libvirt with `--passL:-lvirt` and adds the header
include path via `--passC` (override in `src/libvirt.nim` if libvirt is not
in a standard location).

## Examples

### Connect and inspect the hypervisor

```nim
import libvirt

let conn = openConnect("qemu:///system")
echo conn.getType, " @ ", conn.getHostname
echo "libvirt ", conn.getLibVersion, " / driver ", conn.getVersion

let node = conn.getNodeInfo
echo node.cpus, " CPUs, ", node.memory, " KiB memory"
```

### Manage domains

```nim
import libvirt

let conn = openConnect("qemu:///session")

for dom in conn.listAllDomains:
  echo dom.name, " state=", dom.state.state, " active=", dom.isActive

# Define a persistent domain from an XML description
let dom = conn.defineDomainXML(myDomainXml)
dom.create                       # start it
echo dom.state.state == VIR_DOMAIN_RUNNING
dom.suspend
echo dom.state.state == VIR_DOMAIN_PAUSED
dom.resume
dom.destroy
dom.undefine
```

### Errors

```nim
import libvirt

let conn = openConnect("test:///default")
try:
  discard conn.lookupDomainByName("does-not-exist")
except LibvirtError as e:
  echo e.code, ": ", e.msg    # => 42: Domain not found
```

### Domain lifecycle events

```nim
import libvirt

discard virEventRegisterDefaultImpl()
let conn = openConnect("test:///default")

var started = false
let cb: DomainEventCallback = proc(conn: virConnectPtr, dom: virDomainPtr,
                                   event: cint, detail: cint) {.closure.} =
  if event == VIR_DOMAIN_EVENT_STARTED.cint:
    started = true

let ev = conn.registerDomainEvent(cb)
# ... trigger a domain start, then pump the default event loop:
while not started:
  discard virEventRunDefaultImpl()

ev.deregister
```

## Tests

```sh
nimble test                          # test-driver suite (no hypervisor needed)
LIBVIRT_TEST_QEMU=1 nimble testqemu  # integration tests against qemu:///session
```

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/nimbase/libvirt-nim/issues)
- 👋 Wanna help? [Fork it!](https://github.com/nimbase/libvirt-nim/fork)

### 🎩 License
MIT license | Nim Community.
