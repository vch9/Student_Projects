.PHONY: all final clean

LATEX=xelatex
BIBTEX=biber
PDFDOC=$(shell basename $$PWD).pdf

all:
	mkdir -p build
	$(LATEX)  -shell-escape -output-directory `pwd`/build main
	cp build/main.pdf $(PDFDOC)

final:
	mkdir -p build
	git rev-parse HEAD > commit.tex
	$(LATEX) -shell-escape -output-directory `pwd`/build main
	$(BIBTEX) -output-directory `pwd`/build main
	$(LATEX) -shell-escape -output-directory `pwd`/build main
	$(LATEX) -shell-escape -output-directory `pwd`/build main
	cp build/main.pdf $(PDFDOC)

clean:
	rm -fr build $(PDFDOC)
