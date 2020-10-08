.PHONY: all clean

all:
	dune build impo.exe
	ln -sf _build/default/impo.exe impo

clean:
	dune clean
	rm -fr *~ impo
