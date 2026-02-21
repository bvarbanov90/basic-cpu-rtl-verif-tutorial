TOPLEVEL_LANG ?= verilog
SIM ?= icarus

PWD := $(shell pwd)
PYTHONPATH := $(PWD):$(PYTHONPATH)
export PYTHONPATH

VERILOG_SOURCES := $(PWD)/rtl/simple_cpu.sv
TOPLEVEL := simple_cpu
MODULE := tb.test_simple_cpu

WAVES ?= 1

include $(shell cocotb-config --makefiles)/Makefile.sim
