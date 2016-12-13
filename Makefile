SOURCES := $(wildcard *.moon)
LUAOUT := $(SOURCES:.moon=.lua)

all: $(LUAOUT) run

$(LUAOUT): $(SOURCES)
	moonc $<

run:
	luajit init.lua
