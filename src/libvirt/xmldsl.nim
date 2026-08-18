# libvirt Domain XML DSL.
#
# A single macro `domain` that builds a typed `LibvirtDomain` object
# from an indented, untyped statement block. The object can then be
# rendered to XML with `xml`.
#
# Usage:
#   let d = domain `type`="kvm", id="1":
#     name: "MyGuest"
#     memory unit="KiB": "1048576"
#     os:
#       `type` arch="x86_64", machine="pc": "hvm"
#       boot dev="hd"
#     devices:
#       disk `type`="file", device="disk":
#         driver name="qemu", `type`="qcow2"
#         source file="/var/lib/libvirt/images/guest.qcow2"
#         target dev="vda", bus="virtio"
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import std/[macros, strutils, tables, xmltree]
import ./domain_xml

# ------------------------------------------------------------------
# AST helpers
# ------------------------------------------------------------------

proc getIdent*(e: NimNode): string =
  ## Extracts an identifier from a node, handling backtick-quoted
  ## reserved keywords (`` `type` ``) like std/htmlgen does.
  case e.kind
  of nnkIdent:
    result = e.strVal
  of nnkAccQuoted:
    result = getIdent(e[0])
    for i in 1 ..< e.len:
      result.add getIdent(e[i])
  else:
    error("cannot extract identifier from node: " & toStrLit(e).strVal, e)

proc isAttr(n: NimNode): bool =
  n.kind == nnkExprEqExpr

proc attrName(n: NimNode): string =
  getIdent(n[0])

proc attrValue(n: NimNode): NimNode =
  n[1]

proc attrsOf(e: NimNode): Table[string, NimNode] =
  result = initTable[string, NimNode]()
  for i in 1 ..< e.len:
    if e[i].isAttr:
      result[attrName(e[i])] = attrValue(e[i])

proc elemName(e: NimNode): string =
  case e.kind
  of nnkCommand, nnkCall: getIdent(e[0])
  of nnkIdent: e.strVal
  else: error("unsupported DSL statement", e)

proc textOf(e: NimNode): NimNode =
  ## Returns the text-content node of an element (``name: "x"``),
  ## or a literal "" if the element has none.
  for i in 1 ..< e.len:
    let child = e[i]
    if child.kind == nnkStmtList and child.len == 1:
      let inner = child[0]
      case inner.kind
      of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
        return inner
      of nnkIntLit..nnkUInt64Lit:
        return newCall(ident"$", inner)
      of nnkIdent, nnkDotExpr, nnkCall, nnkInfix, nnkPrefix, nnkPar:
        # Support runtime variables and expressions
        return newCall(ident"$", inner)
      else:
        discard
  newLit("")

proc valOr(node: NimNode, fallback: string): NimNode =
  if node.isNil: newLit(fallback) else: node

proc attrOr(attrs: Table[string, NimNode], key, fallback: string): NimNode =
  if attrs.hasKey(key): attrs[key] else: newLit(fallback)

proc childStmts(e: NimNode): seq[NimNode] =
  ## Returns the child-element statements of a container element,
  ## i.e. the contents of its trailing StmtList.
  for i in 1 ..< e.len:
    let child = e[i]
    if child.kind == nnkStmtList:
      for s in child:
        result.add s

proc enumConv(enumName: string, value: NimNode): NimNode =
  ## Emits `parseEnum[EnumName](value)` for a string-backed enum.
  newCall(
    newNimNode(nnkBracketExpr).add(bindSym"parseEnum", ident(enumName)),
    value)

proc objConstr(typeName: string, fields: varargs[NimNode]): NimNode =
  ## Builds an object-construction node `TypeName(field: val, ...)`.
  result = newNimNode(nnkObjConstr)
  result.add ident(typeName)
  for f in fields:
    result.add f

# ------------------------------------------------------------------
# XML escaping
# ------------------------------------------------------------------

proc escapeXml*(s: string): string =
  ## Escapes `s` for use as XML text or attribute content.
  xmltree.escape(s)

# ------------------------------------------------------------------
# XML rendering of the typed model
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
  if d.driverName.len > 0 or d.driverType.len > 0:
    var dbuf: string
    dbuf.add "<driver"
    dbuf.addAttr("name", d.driverName)
    dbuf.addAttr("type", d.driverType)
    dbuf.add "/>"
    buf.add dbuf
  if d.sourceFile.len > 0 or d.sourceDev.len > 0:
    var sbuf: string
    sbuf.add "<source"
    sbuf.addAttr("file", d.sourceFile)
    sbuf.addAttr("dev", d.sourceDev)
    sbuf.add "/>"
    buf.add sbuf
  if d.targetDev.len > 0:
    var tbuf: string
    tbuf.add "<target"
    tbuf.addAttr("dev", d.targetDev)
    tbuf.addAttr("bus", d.targetBus)
    tbuf.add "/>"
    buf.add tbuf
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

proc renderOs(os: LibvirtOS): string =
  if os.osType.len == 0 and os.boot.len == 0 and os.loader.len == 0 and
     os.nvram.len == 0 and os.kernel.len == 0 and os.initrd.len == 0 and
     os.cmdline.len == 0:
    return ""
  var buf = newStringOfCap(256)
  buf.add "<os>"
  if os.osType.len > 0:
    var tbuf: string
    tbuf.add "<type"
    tbuf.addAttr("arch", os.arch)
    tbuf.addAttr("machine", os.machine)
    tbuf.add ">" & escapeXml(os.osType) & "</type>"
    buf.add tbuf
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
  buf.add "</os>"
  buf

proc renderFeatures(f: LibvirtFeatures): string =
  if not (f.acpi or f.apic or f.pae or f.pvspinlock.len > 0):
    return ""
  var buf = newStringOfCap(128)
  buf.add "<features>"
  if f.acpi: buf.add "<acpi/>"
  if f.apic: buf.add "<apic/>"
  if f.pae: buf.add "<pae/>"
  if f.pvspinlock.len > 0:
    buf.add "<pvspinlock state=\"" & escapeXml(f.pvspinlock) & "\"/>"
  buf.add "</features>"
  buf

proc renderClock(c: LibvirtClock): string =
  if c.offset.len == 0 and c.timezone.len == 0:
    return ""
  var buf = newStringOfCap(64)
  buf.add "<clock"
  buf.addAttr("offset", c.offset)
  buf.addAttr("timezone", c.timezone)
  buf.add "/>"
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

proc xml*(self: LibvirtDomain): string =
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
    var mbuf: string
    mbuf.add "<memory"
    mbuf.addAttr("unit", self.memory.unit)
    mbuf.add ">" & escapeXml(self.memory.value) & "</memory>"
    buf.add mbuf
  if self.currentMemory.value.len > 0:
    var mbuf: string
    mbuf.add "<currentMemory"
    mbuf.addAttr("unit", self.currentMemory.unit)
    mbuf.add ">" & escapeXml(self.currentMemory.value) & "</currentMemory>"
    buf.add mbuf
  if self.vcpu.value.len > 0:
    var vbuf: string
    vbuf.add "<vcpu"
    vbuf.addAttr("placement", self.vcpu.placement)
    vbuf.addAttr("cpuset", self.vcpu.cpuset)
    vbuf.addAttr("current", self.vcpu.current)
    vbuf.add ">" & escapeXml(self.vcpu.value) & "</vcpu>"
    buf.add vbuf
  if self.iothreads.value.len > 0:
    buf.add "<iothreads>" & escapeXml(self.iothreads.value) & "</iothreads>"
  let osStr = renderOs(self.os)
  if osStr.len > 0: buf.add osStr
  if self.cpu.model.len > 0:
    var cbuf: string
    cbuf.add "<cpu>"
    cbuf.add "<model>" & escapeXml(self.cpu.model) & "</model>"
    if self.cpu.topologySockets.len > 0:
      cbuf.add "<topology"
      cbuf.addAttr("sockets", self.cpu.topologySockets)
      cbuf.addAttr("cores", self.cpu.topologyCores)
      cbuf.addAttr("threads", self.cpu.topologyThreads)
      cbuf.add "/>"
    cbuf.add "</cpu>"
    buf.add cbuf
  let featStr = renderFeatures(self.features)
  if featStr.len > 0: buf.add featStr
  let clkStr = renderClock(self.clock)
  if clkStr.len > 0: buf.add clkStr
  let evtStr = renderEvents(self.events)
  if evtStr.len > 0: buf.add evtStr
  if self.disks.len > 0 or self.interfaces.len > 0 or self.serials.len > 0 or
     self.consoles.len > 0 or self.graphics.len > 0 or self.channels.len > 0 or
     self.emulator.len > 0:
    buf.add "<devices>"
    if self.emulator.len > 0:
      buf.add "<emulator>" & escapeXml(self.emulator) & "</emulator>"
    for d in self.disks: buf.add renderDisk(d)
    for i in self.interfaces: buf.add renderInterface(i)
    for s in self.serials: buf.add renderSerial(s)
    for c in self.consoles: buf.add renderConsole(c)
    for g in self.graphics: buf.add renderGraphics(g)
    for ch in self.channels: buf.add renderChannel(ch)
    buf.add "</devices>"
  if self.qemuArgs.len > 0:
    buf.add "<qemu:commandline xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>"
    for a in self.qemuArgs:
      buf.add "<qemu:arg value='" & escapeXml(a) & "'/>"
    buf.add "</qemu:commandline>"
  buf.add "</domain>"
  buf

proc `$`*(self: LibvirtDomain): string =
  xml(self)

# ------------------------------------------------------------------
# The DSL macro
# ------------------------------------------------------------------

proc emitOs(result, d: NimNode, e: NimNode) =
  ## Builds `d.os` from the `<os>` container element.
  let osVar = genSym(nskVar, "os")
  result.add newVarStmt(osVar, newCall(bindSym"LibvirtOS"))
  for sub in childStmts(e):
    let name = elemName(sub)
    let attrs = attrsOf(sub)
    case name
    of "type":
      result.add newAssignment(newDotExpr(osVar, ident"osType"), textOf(sub))
      result.add newAssignment(newDotExpr(osVar, ident"arch"),
                               attrOr(attrs, "arch", ""))
      result.add newAssignment(newDotExpr(osVar, ident"machine"),
                               attrOr(attrs, "machine", ""))
    of "boot":
      result.add newCall(
        newDotExpr(newDotExpr(osVar, ident"boot"), ident"add"),
        enumConv("LibvirtBootDevice", attrOr(attrs, "dev", "hd")))
    of "loader":
      result.add newAssignment(newDotExpr(osVar, ident"loader"), textOf(sub))
    of "nvram":
      result.add newAssignment(newDotExpr(osVar, ident"nvram"), textOf(sub))
    of "kernel":
      result.add newAssignment(newDotExpr(osVar, ident"kernel"), textOf(sub))
    of "initrd":
      result.add newAssignment(newDotExpr(osVar, ident"initrd"), textOf(sub))
    of "cmdline":
      result.add newAssignment(newDotExpr(osVar, ident"cmdline"), textOf(sub))
    else:
      error("unsupported <os> element: '" & name & "'", sub)
  result.add newAssignment(newDotExpr(d, ident"os"), osVar)

proc featureAssign(fVar: NimNode, name: string, node: NimNode): NimNode =
  case name
  of "acpi":
    newAssignment(newDotExpr(fVar, ident"acpi"), newLit(true))
  of "apic":
    newAssignment(newDotExpr(fVar, ident"apic"), newLit(true))
  of "pae":
    newAssignment(newDotExpr(fVar, ident"pae"), newLit(true))
  else:
    error("unsupported feature: '" & name & "'", node)
    newEmptyNode()

proc emitFeatures(result, d: NimNode, e: NimNode) =
  let fVar = genSym(nskVar, "features")
  result.add newVarStmt(fVar, newCall(bindSym"LibvirtFeatures"))
  let body = e[1]  # the StmtList child
  if body.len == 1 and body[0].kind == nnkBracket:
    # Bracket form: [acpi, apic] or ["acpi" "apic"] or ["acpi", "apic"]
    for item in body[0]:
      case item.kind
      of nnkIdent:
        result.add featureAssign(fVar, $item, item)
      of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
        result.add featureAssign(fVar, item.strVal, item)
      of nnkCommand:
        # space-separated strings: ["acpi" "apic"]
        for child in item:
          if child.kind in {nnkStrLit, nnkRStrLit, nnkTripleStrLit}:
            result.add featureAssign(fVar, child.strVal, child)
      else:
        error("unsupported feature in bracket", item)
  else:
    # Block form: acpi apic (or single items)
    for sub in childStmts(e):
      let name = elemName(sub)
      result.add featureAssign(fVar, name, sub)
  result.add newAssignment(newDotExpr(d, ident"features"), fVar)

proc emitQemuCommandline(result, d: NimNode, e: NimNode) =
  ## Builds `d.qemuArgs` from a `qemu_commandline` block of
  ## `qemu_arg value="..."` elements.
  for sub in childStmts(e):
    let name = elemName(sub)
    if name != "qemu_arg":
      error("unsupported <qemu_commandline> element: '" & name & "'", sub)
    let attrs = attrsOf(sub)
    result.add newCall(
      newDotExpr(newDotExpr(d, ident"qemuArgs"), ident"add"),
      attrOr(attrs, "value", ""))

proc deviceKind(name: string): string =
  ## Returns the domain field that holds the given device element.
  case name
  of "disk": "disks"
  of "interface": "interfaces"
  of "serial": "serials"
  of "console": "consoles"
  of "graphics": "graphics"
  of "channel": "channels"
  else: ""

proc buildDevice(sub: NimNode): NimNode =
  let name = elemName(sub)
  let attrs = attrsOf(sub)
  case name
  of "disk":
    var disk: string
    var device: string
    if attrs.hasKey("type"): disk = "file"
    if attrs.hasKey("device"): device = "disk"
    var driverName, driverType, sourceFile, sourceDev, targetDev, targetBus: NimNode
    var readonly = newLit(false)
    for child in childStmts(sub):
      let cname = elemName(child)
      let ca = attrsOf(child)
      case cname
      of "driver":
        driverName = attrOr(ca, "name", "")
        driverType = attrOr(ca, "type", "")
      of "source":
        sourceFile = attrOr(ca, "file", "")
        sourceDev = attrOr(ca, "dev", "")
      of "target":
        targetDev = attrOr(ca, "dev", "")
        targetBus = attrOr(ca, "bus", "")
      of "readonly":
        readonly = newLit(true)
      else:
        error("unsupported <disk> element: '" & cname & "'", child)
    objConstr("LibvirtDisk",
      newColonExpr(ident"diskType", newLit(disk)),
      newColonExpr(ident"device", newLit(device)),
      newColonExpr(ident"driverName", driverName.valOr("")),
      newColonExpr(ident"driverType", driverType.valOr("")),
      newColonExpr(ident"sourceFile", sourceFile.valOr("")),
      newColonExpr(ident"sourceDev", sourceDev.valOr("")),
      newColonExpr(ident"targetDev", targetDev.valOr("")),
      newColonExpr(ident"targetBus", targetBus.valOr("")),
      newColonExpr(ident"readonly", readonly))
  of "interface":
    var sourceNetwork, sourceBridge, mac, model, targetDev: NimNode
    for child in childStmts(sub):
      let cname = elemName(child)
      let ca = attrsOf(child)
      case cname
      of "source":
        sourceNetwork = attrOr(ca, "network", "")
        sourceBridge = attrOr(ca, "bridge", "")
      of "mac":
        mac = attrOr(ca, "address", "")
      of "model":
        model = attrOr(ca, "type", "")
      of "target":
        targetDev = attrOr(ca, "dev", "")
      else:
        error("unsupported <interface> element: '" & cname & "'", child)
    objConstr("LibvirtInterface",
      newColonExpr(ident"ifaceType", attrOr(attrs, "type", "")),
      newColonExpr(ident"sourceNetwork", sourceNetwork.valOr("")),
      newColonExpr(ident"sourceBridge", sourceBridge.valOr("")),
      newColonExpr(ident"mac", mac.valOr("")),
      newColonExpr(ident"model", model.valOr("")),
      newColonExpr(ident"targetDev", targetDev.valOr("")))
  of "serial":
    objConstr("LibvirtSerial",
      newColonExpr(ident"targetPort", attrOr(attrs, "port", "0")),
      newColonExpr(ident"sourcePath", newLit("")),
      newColonExpr(ident"sourceType", attrOr(attrs, "type", "")))
  of "console":
    var targetType, targetPort, sourcePath: NimNode
    for child in childStmts(sub):
      let cname = elemName(child)
      let ca = attrsOf(child)
      case cname
      of "source":
        sourcePath = attrOr(ca, "path", "")
      of "target":
        targetType = attrOr(ca, "type", "serial")
        targetPort = attrOr(ca, "port", "0")
      else:
        error("unsupported <console> element: '" & cname & "'", child)
    objConstr("LibvirtConsole",
      newColonExpr(ident"targetType", targetType.valOr("serial")),
      newColonExpr(ident"targetPort", targetPort.valOr("0")),
      newColonExpr(ident"sourcePath", sourcePath.valOr("")),
      newColonExpr(ident"sourceType", attrOr(attrs, "type", "")))
  of "graphics":
    objConstr("LibvirtGraphics",
      newColonExpr(ident"graphicsType", attrOr(attrs, "type", "")),
      newColonExpr(ident"port", attrOr(attrs, "port", "")),
      newColonExpr(ident"listen", attrOr(attrs, "listen", "")),
      newColonExpr(ident"autoport", attrOr(attrs, "autoport", "")),
      newColonExpr(ident"passwd", attrOr(attrs, "passwd", "")))
  of "channel":
    var sourceMode, sourcePath, targetType, targetName: NimNode
    for child in childStmts(sub):
      let cname = elemName(child)
      let ca = attrsOf(child)
      case cname
      of "source":
        sourceMode = attrOr(ca, "mode", "")
        sourcePath = attrOr(ca, "path", "")
      of "target":
        targetType = attrOr(ca, "type", "")
        targetName = attrOr(ca, "name", "")
      else:
        error("unsupported <channel> element: '" & cname & "'", child)
    objConstr("LibvirtChannel",
      newColonExpr(ident"channelType", attrOr(attrs, "type", "")),
      newColonExpr(ident"sourceMode", sourceMode.valOr("")),
      newColonExpr(ident"sourcePath", sourcePath.valOr("")),
      newColonExpr(ident"targetType", targetType.valOr("")),
      newColonExpr(ident"targetName", targetName.valOr("")))
  else:
    error("unsupported device element: '" & name & "'", sub)

proc emitDevices(result, d: NimNode, e: NimNode) =
  ## Builds `d.disks`, `d.interfaces`, ... from the `<devices>` container.
  for sub in childStmts(e):
    let name = elemName(sub)
    if name == "emulator":
      result.add newAssignment(newDotExpr(d, ident"emulator"), textOf(sub))
      continue
    let kind = deviceKind(name)
    if kind.len == 0:
      error("unsupported device element: '" & name & "'", sub)
    result.add newCall(
      newDotExpr(newDotExpr(d, ident(kind)), ident"add"),
      buildDevice(sub))

proc emitElement(result, d: NimNode, e: NimNode) =
  ## Emits assignments on the domain temp var `d` for one body statement `e`.
  let name = elemName(e)
  let attrs = attrsOf(e)
  case name
  of "name":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"metadata"), ident"name"), textOf(e))
  of "uuid":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"metadata"), ident"uuid"), textOf(e))
  of "genid":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"metadata"), ident"genid"), textOf(e))
  of "title":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"metadata"), ident"title"), textOf(e))
  of "description":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"metadata"), ident"description"), textOf(e))
  of "memory":
    result.add newAssignment(newDotExpr(d, ident"memory"),
      objConstr("LibvirtMemory",
        newColonExpr(ident"value", textOf(e)),
        newColonExpr(ident"unit", attrOr(attrs, "unit", ""))))
  of "currentMemory":
    result.add newAssignment(newDotExpr(d, ident"currentMemory"),
      objConstr("LibvirtMemory",
        newColonExpr(ident"value", textOf(e)),
        newColonExpr(ident"unit", attrOr(attrs, "unit", ""))))
  of "vcpu":
    result.add newAssignment(newDotExpr(d, ident"vcpu"),
      objConstr("LibvirtVcpu",
        newColonExpr(ident"value", textOf(e)),
        newColonExpr(ident"placement", attrOr(attrs, "placement", "")),
        newColonExpr(ident"cpuset", attrOr(attrs, "cpuset", "")),
        newColonExpr(ident"current", attrOr(attrs, "current", ""))))
  of "iothreads":
    result.add newAssignment(newDotExpr(d, ident"iothreads"),
      objConstr("LibvirtIothreads",
        newColonExpr(ident"value", textOf(e))))
  of "os":
    emitOs(result, d, e)
  of "features":
    emitFeatures(result, d, e)
  of "clock":
    result.add newAssignment(newDotExpr(d, ident"clock"),
      objConstr("LibvirtClock",
        newColonExpr(ident"offset", attrOr(attrs, "offset", "")),
        newColonExpr(ident"timezone", attrOr(attrs, "timezone", ""))))
  of "on_poweroff":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"events"), ident"onPoweroff"),
      enumConv("LibvirtOnAction", textOf(e)))
  of "on_reboot":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"events"), ident"onReboot"),
      enumConv("LibvirtOnAction", textOf(e)))
  of "on_crash":
    result.add newAssignment(newDotExpr(newDotExpr(d, ident"events"), ident"onCrash"),
      enumConv("LibvirtOnAction", textOf(e)))
  of "devices":
    emitDevices(result, d, e)
  of "qemu_commandline":
    emitQemuCommandline(result, d, e)
  else:
    error("unsupported domain element: '" & name & "'", e)

macro domain*(args: varargs[untyped]): untyped =
  ## Builds a `LibvirtDomain` object from an indented DSL block.
  ##
  ## Root attributes (`` `type`="kvm", id="1" ``) become attributes on
  ## the `<domain>` element; indented statements become its children.
  var attrs: seq[tuple[name: string, val: NimNode]]
  var body: NimNode = nil
  for a in args:
    if a.isAttr:
      attrs.add((attrName(a), attrValue(a)))
    else:
      body = a

  let d = genSym(nskVar, "domain")
  result = newStmtList()
  result.add newVarStmt(d, newCall(bindSym"LibvirtDomain"))

  for (name, val) in attrs:
    case name
    of "type":
      result.add newAssignment(newDotExpr(d, ident"virtType"), val)
    of "id":
      result.add newAssignment(newDotExpr(d, ident"id"), val)
    else:
      error("unsupported domain attribute: '" & name & "'")

  if body != nil:
    for e in body:
      emitElement(result, d, e)

  result.add d
