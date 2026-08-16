# Nim bindings for libvirt.
#
# Official page: https://libvirt.org/
#
# (c) 2026 George Lemon | Nimbase Community MIT License
#          https://github.com/openpeeps/libvirt-nim

{.passL:"-L/opt/local/lib -lvirt", passC:"-I /opt/local/include".}

import ./libvirt/bindings/common
import ./libvirt/bindings/[host, domain, network, storage, stream, event, virterror]
import ./libvirt/api

export common, host, domain, network, storage, stream, event, virterror, api
