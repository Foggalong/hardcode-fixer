
BIN ?= fix
PREFIX ?= /usr/local

$(BIN):
	@:

install:
	install fix.sh $(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(PREFIX)/bin/$(BIN)
