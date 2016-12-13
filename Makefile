SOURCES := $(wildcard *.moon)
LUAOUT := $(SOURCES:.moon=.lua)

all: build run

build: $(LUAOUT)

$(LUAOUT): $(SOURCES)
	moonc $<

run:
	luajit init.lua
