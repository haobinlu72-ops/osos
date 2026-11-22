#!/bin/sh
# QEMU 4.x needs an explicit RV64 executable/architecture with gdb-multiarch.
exec gdb-multiarch -ex 'file bin/kernel' -ex 'set architecture riscv:rv64' "$@"
