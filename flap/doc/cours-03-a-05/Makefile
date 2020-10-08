# -*- mode:makefile -*-
TARGETS=marthe.html marthepp.html
DIR=doc/

.PHONY: all clean

all: $(TARGETS)

clean:
	rm -f *.{html,cmo,cmi,ocamldoc} style.css

%.html: %.ml
	ocamldoc -d $(DIR) -keep-code -charset utf8 -html $<
