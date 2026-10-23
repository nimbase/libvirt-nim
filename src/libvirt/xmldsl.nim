# libvirt Domain XML rendering.
#
# Renders typed LibvirtDomain objects to XML strings via `toXML`.
#
# Usage:
#   var d = LibvirtDomain(
#     virtType: "kvm",
#     metadata: LibvirtMetadata(name: "MyGuest"),
#     memory: LibvirtMemory(value: "1048576", unit: "KiB"),
#     os: LibvirtOS(
#       osType: "hvm", arch: "x86_64", machine: "pc",
#       boot: @[bdHardDisk]
#     ),
#     disks: @[LibvirtDisk(
#       diskType: "file", device: "disk",
#       sourceFile: "/var/lib/libvirt/images/guest.qcow2",
#       targetDev: "vda", targetBus: "virtio"
#     )]
#   )
#   echo toXML(d)
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/strutils
import std/xmltree
import ./domain_xml

# ------------------------------------------------------------------
# XML escaping
# ------------------------------------------------------------------

proc escapeXml*(s: string): string =
  ## Escapes `s` for use as XML text or attribute content.
  xmltree.escape(s)

# ------------------------------------------------------------------
# XML rendering helpers
# ------------------------------------------------------------------

proc addAttr(buf: var string, name, value: string) =
  if value.len > 0:
    buf.add " " & name & "=\"" & escapeXml(value) & "\""

proc renderDisk(d: LibvirtDisk): string =
  var buf = newStringOfCap(256)
  buf.add "<disk"
  buf.addAttr("type", d.diskType)
  buf.addAttr("device", d.device)
  buf.add ">"
  if d.driverName.len > 0 or d.driverType.len > 0 or d.driverCache.len > 0 or
      d.driverIo.len > 0 or d.driverDiscard.len > 0:
    buf.add "<driver"
    buf.addAttr("name", d.driverName)
    buf.addAttr("type", d.driverType)
    buf.addAttr("cache", d.driverCache)
    buf.addAttr("io", d.driverIo)
    buf.addAttr("discard", d.driverDiscard)
    buf.add "/>"
  if d.sourceFile.len > 0 or d.sourceDev.len > 0:
    buf.add "<source"
    buf.addAttr("file", d.sourceFile)
    buf.addAttr("dev", d.sourceDev)
    buf.add "/>"
  if d.targetDev.len > 0:
    buf.add "<target"
    buf.addAttr("dev", d.targetDev)
    buf.addAttr("bus", d.targetBus)
    buf.add "/>"
  if d.readonly:
    buf.add "<readonly/>"
  buf.add "</disk>"
  buf

proc renderInterface(i: LibvirtInterface): string =
  var buf = newStringOfCap(256)
  buf.add "<interface"
  buf.addAttr("type", i.ifaceType)
  buf.add ">"
  if i.sourceNetwork.len > 0:
    buf.add "<source network=\"" & escapeXml(i.sourceNetwork) & "\"/>"
  elif i.sourceBridge.len > 0:
    buf.add "<source bridge=\"" & escapeXml(i.sourceBridge) & "\"/>"
  if i.mac.len > 0:
    buf.add "<mac address=\"" & escapeXml(i.mac) & "\"/>"
  if i.model.len > 0:
    buf.add "<model type=\"" & escapeXml(i.model) & "\"/>"
  if i.targetDev.len > 0:
    buf.add "<target dev=\"" & escapeXml(i.targetDev) & "\"/>"
  buf.add "</interface>"
  buf

proc renderSerial(s: LibvirtSerial): string =
  var buf = newStringOfCap(128)
  buf.add "<serial"
  buf.addAttr("type", s.sourceType)
  buf.add ">"
  if s.sourcePath.len > 0:
    buf.add "<source path=\"" & escapeXml(s.sourcePath) & "\"/>"
  if s.targetPort.len > 0:
    buf.add "<target port=\"" & escapeXml(s.targetPort) & "\"/>"
  buf.add "</serial>"
  buf

proc renderConsole(c: LibvirtConsole): string =
  var buf = newStringOfCap(128)
  buf.add "<console"
  buf.addAttr("type", c.sourceType)
  buf.add ">"
  if c.sourcePath.len > 0:
    buf.add "<source path=\"" & escapeXml(c.sourcePath) & "\"/>"
  if c.targetPort.len > 0:
    buf.add "<target type=\"" & escapeXml(c.targetType) & "\" port=\"" &
      escapeXml(c.targetPort) & "\"/>"
  buf.add "</console>"
  buf

proc renderGraphics(g: LibvirtGraphics): string =
  var buf = newStringOfCap(128)
  buf.add "<graphics"
  buf.addAttr("type", g.graphicsType)
  buf.addAttr("port", g.port)
  buf.addAttr("listen", g.listen)
  buf.addAttr("autoport", g.autoport)
  buf.addAttr("passwd", g.passwd)
  buf.add "/>"
  buf

proc renderChannel(c: LibvirtChannel): string =
  var buf = newStringOfCap(256)
  buf.add "<channel"
  buf.addAttr("type", c.channelType)
  buf.add ">"
  if c.sourceMode.len > 0 or c.sourcePath.len > 0:
    buf.add "<source"
    buf.addAttr("mode", c.sourceMode)
    buf.addAttr("path", c.sourcePath)
    buf.add "/>"
  if c.targetType.len > 0 or c.targetName.len > 0:
    buf.add "<target"
    buf.addAttr("type", c.targetType)
    buf.addAttr("name", c.targetName)
    buf.add "/>"
  buf.add "</channel>"
  buf

proc renderMemoryBacking(mb: LibvirtMemoryBacking): string =
  if mb.sourceType.len == 0 and mb.accessMode.len == 0:
    return ""
  var buf = newStringOfCap(128)
  buf.add "<memoryBacking>"
  if mb.sourceType.len > 0:
    buf.add "<source type=\"" & escapeXml(mb.sourceType) & "\"/>"
  if mb.accessMode.len > 0:
    buf.add "<access mode=\"" & escapeXml(mb.accessMode) & "\"/>"
  buf.add "</memoryBacking>"
  buf

proc renderFilesystem(fs: LibvirtFilesystem): string =
  var buf = newStringOfCap(256)
  buf.add "<filesystem"
  buf.addAttr("type", fs.fsType)
  buf.addAttr("accessmode", fs.accessmode)
  buf.add ">"
  if fs.driverType.len > 0:
    buf.add "<driver"
    buf.addAttr("type", fs.driverType)
    buf.addAttr("queue", fs.driverQueue)
    buf.add "/>"
  if fs.sourceDir.len > 0:
    buf.add "<source dir=\"" & escapeXml(fs.sourceDir) & "\"/>"
  elif fs.sourceSocket.len > 0:
    buf.add "<source socket=\"" & escapeXml(fs.sourceSocket) & "\"/>"
  if fs.targetDir.len > 0:
    buf.add "<target dir=\"" & escapeXml(fs.targetDir) & "\"/>"
  buf.add "</filesystem>"
  buf

proc renderOs(os: LibvirtOS): string =
  if os.osType.len == 0 and os.boot.len == 0 and os.loader.len == 0 and
     os.nvram.len == 0 and os.kernel.len == 0 and os.initrd.len == 0 and
     os.cmdline.len == 0 and os.init.len == 0 and os.initarg.len == 0:
    return ""
  var buf = newStringOfCap(256)
  buf.add "<os>"
  if os.osType.len > 0:
    buf.add "<type"
    buf.addAttr("arch", os.arch)
    buf.addAttr("machine", os.machine)
    buf.add ">" & escapeXml(os.osType) & "</type>"
  if os.loader.len > 0:
    buf.add "<loader>" & escapeXml(os.loader) & "</loader>"
  if os.nvram.len > 0:
    buf.add "<nvram>" & escapeXml(os.nvram) & "</nvram>"
  for b in os.boot:
    buf.add "<boot dev=\"" & $b & "\"/>"
  if os.kernel.len > 0:
    buf.add "<kernel>" & escapeXml(os.kernel) & "</kernel>"
  if os.initrd.len > 0:
    buf.add "<initrd>" & escapeXml(os.initrd) & "</initrd>"
  if os.cmdline.len > 0:
    buf.add "<cmdline>" & escapeXml(os.cmdline) & "</cmdline>"
  if os.init.len > 0:
    buf.add "<init>" & escapeXml(os.init) & "</init>"
  for a in os.initarg:
    buf.add "<initarg>" & escapeXml(a) & "</initarg>"
  buf.add "</os>"
  buf

proc renderFeatures(f: LibvirtFeatures): string =
  if not (f.acpi or f.apic or f.pae or f.pvspinlock.len > 0 or f.kvmHidden or f.vmport.len > 0):
    return ""
  var buf = newStringOfCap(128)
  buf.add "<features>"
  if f.acpi: buf.add "<acpi/>"
  if f.apic: buf.add "<apic/>"
  if f.pae: buf.add "<pae/>"
  if f.kvmHidden:
    buf.add "<kvm><hidden state='on'/></kvm>"
  if f.vmport.len > 0:
    buf.add "<vmport state=\"" & escapeXml(f.vmport) & "\"/>"
  if f.pvspinlock.len > 0:
    buf.add "<pvspinlock state=\"" & escapeXml(f.pvspinlock) & "\"/>"
  buf.add "</features>"
  buf

proc renderClock(c: LibvirtClock): string =
  if c.offset.len == 0 and c.timezone.len == 0 and c.kvmclockPresent.len == 0 and c.hpetPresent.len == 0:
    return ""
  var buf = newStringOfCap(128)
  buf.add "<clock"
  buf.addAttr("offset", c.offset)
  buf.addAttr("timezone", c.timezone)
  if c.kvmclockPresent.len == 0 and c.hpetPresent.len == 0 and c.rtcTickPolicy.len == 0 and c.pitTickPolicy.len == 0:
    buf.add "/>"
  else:
    buf.add ">"
    if c.kvmclockPresent.len > 0:
      buf.add "<timer name='kvmclock' present='" & escapeXml(c.kvmclockPresent) & "'/>"
    if c.hpetPresent.len > 0:
      buf.add "<timer name='hpet' present='" & escapeXml(c.hpetPresent) & "'/>"
    if c.rtcTickPolicy.len > 0:
      buf.add "<timer name='rtc' tickpolicy='" & escapeXml(c.rtcTickPolicy) & "'/>"
    if c.pitTickPolicy.len > 0:
      buf.add "<timer name='pit' tickpolicy='" & escapeXml(c.pitTickPolicy) & "'/>"
    buf.add "</clock>"
  buf

proc renderEvents(e: LibvirtEvents): string =
  var buf = newStringOfCap(128)
  if e.onPoweroff != oaDestroy:
    buf.add "<on_poweroff>" & $e.onPoweroff & "</on_poweroff>"
  if e.onReboot != oaDestroy:
    buf.add "<on_reboot>" & $e.onReboot & "</on_reboot>"
  if e.onCrash != oaDestroy:
    buf.add "<on_crash>" & $e.onCrash & "</on_crash>"
  buf

proc renderSeclabel(s: LibvirtSeclabel): string =
  if s.seclabelType.len == 0 and s.model.len == 0:
    return ""
  var buf = newStringOfCap(128)
  buf.add "<seclabel"
  buf.addAttr("type", s.seclabelType)
  buf.addAttr("model", s.model)
  buf.addAttr("relabel", s.relabel)
  buf.add ">"
  if s.label.len > 0:
    buf.add "<label>" & escapeXml(s.label) & "</label>"
  if s.baselabel.len > 0:
    buf.add "<baselabel>" & escapeXml(s.baselabel) & "</baselabel>"
  if s.imagelabel.len > 0:
    buf.add "<imagelabel>" & escapeXml(s.imagelabel) & "</imagelabel>"
  buf.add "</seclabel>"
  buf

# ------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------

proc toXML*(self: LibvirtDomain): string =
  ## Renders the domain as an XML string suitable for libvirt.
  var buf = newStringOfCap(1024)
  buf.add "<domain"
  buf.addAttr("type", self.virtType)
  buf.addAttr("id", self.id)
  buf.add ">"
  if self.metadata.name.len > 0:
    buf.add "<name>" & escapeXml(self.metadata.name) & "</name>"
  if self.metadata.uuid.len > 0:
    buf.add "<uuid>" & escapeXml(self.metadata.uuid) & "</uuid>"
  if self.metadata.title.len > 0:
    buf.add "<title>" & escapeXml(self.metadata.title) & "</title>"
  if self.metadata.description.len > 0:
    buf.add "<description>" & escapeXml(self.metadata.description) & "</description>"
  if self.memory.value.len > 0:
    buf.add "<memory"
    buf.addAttr("unit", self.memory.unit)
    buf.add ">" & escapeXml(self.memory.value) & "</memory>"
  if self.currentMemory.value.len > 0:
    buf.add "<currentMemory"
    buf.addAttr("unit", self.currentMemory.unit)
    buf.add ">" & escapeXml(self.currentMemory.value) & "</currentMemory>"
  if self.vcpu.value.len > 0:
    buf.add "<vcpu"
    buf.addAttr("placement", self.vcpu.placement)
    buf.addAttr("cpuset", self.vcpu.cpuset)
    buf.addAttr("current", self.vcpu.current)
    buf.add ">" & escapeXml(self.vcpu.value) & "</vcpu>"
  if self.iothreads.value.len > 0:
    buf.add "<iothreads>" & escapeXml(self.iothreads.value) & "</iothreads>"
  let osStr = renderOs(self.os)
  if osStr.len > 0: buf.add osStr
  if self.cpu.model.len > 0 or self.cpu.mode.len > 0:
    buf.add "<cpu"
    buf.addAttr("mode", self.cpu.mode)
    buf.addAttr("check", self.cpu.check)
    buf.add ">"
    if self.cpu.model.len > 0:
      buf.add "<model>" & escapeXml(self.cpu.model) & "</model>"
    if self.cpu.topologySockets.len > 0:
      buf.add "<topology"
      buf.addAttr("sockets", self.cpu.topologySockets)
      buf.addAttr("cores", self.cpu.topologyCores)
      buf.addAttr("threads", self.cpu.topologyThreads)
      buf.add "/>"
    for fp in self.cpu.featurePolicy:
      buf.add "<feature policy='" & escapeXml(fp.policy) & "' name='" & escapeXml(fp.name) & "'/>"
    buf.add "</cpu>"
  let featStr = renderFeatures(self.features)
  if featStr.len > 0: buf.add featStr
  let clkStr = renderClock(self.clock)
  if clkStr.len > 0: buf.add clkStr
  let evtStr = renderEvents(self.events)
  if evtStr.len > 0: buf.add evtStr
  let mbStr = renderMemoryBacking(self.memoryBacking)
  if mbStr.len > 0: buf.add mbStr
  let seclabelStr = renderSeclabel(self.seclabel)
  if seclabelStr.len > 0: buf.add seclabelStr
  if self.disks.len > 0 or self.interfaces.len > 0 or self.serials.len > 0 or
     self.consoles.len > 0 or self.graphics.len > 0 or self.channels.len > 0 or
     self.filesystems.len > 0 or self.emulator.len > 0:
    buf.add "<devices>"
    if self.emulator.len > 0:
      buf.add "<emulator>" & escapeXml(self.emulator) & "</emulator>"
    for d in self.disks: buf.add renderDisk(d)
    for i in self.interfaces: buf.add renderInterface(i)
    for s in self.serials: buf.add renderSerial(s)
    for c in self.consoles: buf.add renderConsole(c)
    for g in self.graphics: buf.add renderGraphics(g)
    for ch in self.channels: buf.add renderChannel(ch)
    for fs in self.filesystems: buf.add renderFilesystem(fs)
    buf.add "</devices>"
  if self.qemuArgs.len > 0:
    buf.add "<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>"
    for a in self.qemuArgs:
      buf.add "<qemu:arg value='" & escapeXml(a) & "'/>"
    buf.add "</qemu:commandline>"
  buf.add "</domain>"
  buf

proc `$`*(self: LibvirtDomain): string =
  toXML(self)
