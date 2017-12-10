PROJECT= ppx_ok_monad

.PHONY: build, install clean

build:
	jbuilder build

install: build
	jbuilder install

uninstall:
	jbuilder uninstall

clean:
	jbuilder clean

