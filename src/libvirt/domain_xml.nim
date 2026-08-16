# libvirt Domain XML type model.
# Umbrella module re-exporting all domain types.
#
# (c) 2026 George Lemon | Nimbase Community MIT License

import ./domain/common
import ./domain/metadata
import ./domain/os
import ./domain/cpu
import ./domain/clock
import ./domain/devices
import ./domain/domain as libdomain

export common
export metadata
export os
export cpu
export clock
export devices
export libdomain
