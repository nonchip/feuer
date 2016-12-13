SOURCES := $(wildcard *.moon)
LUAOUT := $(SOURCES:.moon=.lua)

all: run

build: $(LUAOUT)

$(LUAOUT): $(SOURCES)
	moonc $<

run: build
	luajit init.lua
