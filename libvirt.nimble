# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "Bindings for Libvirt"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "nim >= 2.0.0"

task test, "Run tests":
  exec "nim c -r tests/test_connect.nim"

task testqemu, "Run QEMU integration tests (set LIBVIRT_TEST_QEMU=1)":
  exec "nim c -r tests/test_qemu.nim"
