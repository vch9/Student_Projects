SOURCES = main.c meta.c parser.c pixel.c thread.c selection.c view.c transform.c formats.c draw.c script.c options.c man/man.c
OBJ = main.o meta.o parser.o pixel.o thread.o selection.o view.o transform.o formats.o draw.o script.o options.o man.o
LIBS = -lreadline -lSDL2 -lSDL2_image -ltiff

all: cimp test_draw test_selection test_transform

cimp : $(OBJ)
	gcc -o cimp $(OBJ) $(LIBS)

test_draw : testDraw.o pixel.o draw.o view.o selection.o
	gcc -o test_draw testDraw.o pixel.o draw.o view.o selection.o $(LIBS)

test_selection: testSelection.o pixel.o selection.o view.o
	gcc -o test_selection testSelection.o pixel.o selection.o view.o $(LIBS)

test_transform: testTransform.o pixel.o selection.o view.o transform.o
	gcc -o test_transform testTransform.o pixel.o selection.o view.o transform.o $(LIBS)

draw.o : draw.c draw.h view.h pixel.h selection.h
	gcc -c draw.c

man.o: man/man.c man/man.h 
	gcc -c man/man.c

selection.o : selection.c selection.h view.h pixel.h
	gcc -c selection.c

parser.o : parser.c parser.h view.h thread.h selection.h draw.h transform.h formats.h man/man.h
	gcc -c parser.c

meta.o : meta.c meta.h view.h
	gcc -c meta.c

pixel.o : pixel.c pixel.h
	gcc -c pixel.c

view.o : view.c view.h
	gcc -c view.c

transform.o : transform.c transform.h view.h pixel.h selection.h
	gcc -c transform.c

formats.o : formats.c formats.h parser.h
	gcc -c formats.c

script.o : script.c script.h parser.h
	gcc -c script.c

options.o : options.c options.h
	gcc -c options.c

thread.o : thread.c thread.h parser.h view.h
	gcc -c thread.c

clean :
	rm -f *.o
