ifndef BINDIR
  BINDIR= $(shell opam config var bin)
endif

PROJECT= ppx_ok_monad
PPX= ppx_ok_monad

$(PPX): $(PPX).ml
	ocamlfind ocamlc -linkpkg -o $@ $< -package compiler-libs.common

.PHONY: clean, distclean

clean:
	rm -f *.cm* *.o

distclean: clean
	rm -f $(PPX)

install: $(PPX)
	ocamlfind install $(PROJECT) $(PPX) META

uninstall:
	ocamlfind remove $(PROJECT)

