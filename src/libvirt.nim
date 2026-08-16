# Nim bindings for libvirt.
#
# Official page: https://libvirt.org/
#
# (c) 2026 George Lemon | Nimbase Community MIT License
#          https://github.com/openpeeps/libvirt-nim

{.passL: gorge("pkg-config --libs libvirt").}
{.passC: gorge("pkg-config --cflags libvirt").}

import ./libvirt/bindings/common
import ./libvirt/bindings/[host, domain, network, storage, stream, event, virterror]
import ./libvirt/domain_xml
import ./libvirt/xmldsl
import ./libvirt/api

export common, host, domain, network, storage, stream, event, virterror
export domain_xml, xmldsl, api
