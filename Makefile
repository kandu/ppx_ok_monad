ifndef BINDIR
  BINDIR= $(shell opam config var bin)
endif

PROJECT= ok_monad
PPX= ppx_ok_monad

$(PPX): $(PPX).ml
	ocamlfind ocamlc -linkpkg -o $@ $< -package compiler-libs.common

.PHONY: clean, distclean

clean:
	rm -f *.cm* *.o

distclean: clean
	rm -f $(PPX)

install: $(PPX)
	install -m 755 $(PPX) $(BINDIR)
	ocamlfind install $(PROJECT) META

uninstall:
	rm -f $(BINDIR)/$(PPX)
	ocamlfind remove $(PROJECT)

