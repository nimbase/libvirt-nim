# Nim bindings for libvirt.
#
# Official page: https://libvirt.org/
#
# (c) 2026 George Lemon | Nimbase Community MIT License
#          https://github.com/openpeeps/libvirt-nim

when defined(windows):
  when fileExists("C:/msys64/mingw64/lib/libvirt.dll.a"):
    {.passL: "-LC:/msys64/mingw64/lib -lvirt".}
    {.passC: "-IC:/msys64/mingw64/include".}
  else:
    {.passL: "-lvirt".}
    {.passC: "".}
else:
  {.passL: gorge("pkg-config --libs libvirt").}
  {.passC: gorge("pkg-config --cflags libvirt").}

import ./libvirt/bindings/common
import ./libvirt/bindings/[host, domain, network, storage, stream, event, virterror]
import ./libvirt/domain_xml
import ./libvirt/xmldsl
import ./libvirt/api

export common, host, domain, network, storage, stream, event, virterror
export domain_xml, xmldsl, api
