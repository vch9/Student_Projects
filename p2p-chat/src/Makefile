CFLAGS= -g
LDLIBS = -lpthread -lm -lreadline
OBJS = client.o receive_msg.o contact.o data.o neighbour.o message.o tlv_builder.o list.o pmtu.o file_transfert.o

client: $(OBJS)
	gcc -g -o client $(OBJS) $(LDLIBS)

receive_msg.o: receive_msg.c receive_msg.h message.h struct.h data.h neighbour.h list.h client.h
	gcc -c receive_msg.c

contact.o: contact.c contact.h list.h struct.h
	gcc -c contact.c

data.o: data.c data.h neighbour.h list.h struct.h
	gcc -c data.c

neighbour.o: neighbour.c neighbour.h list.h message.h struct.h pmtu.h
	gcc -c neighbour.c

message.o: message.c message.h tlv_builder.h
	gcc -c message.c

tlv_builder.o: tlv_builder.c tlv_builder.h
	gcc -c tlv_builder.c

list.o: list.c list.h struct.h
	gcc -c list.c

pmtu.o: pmtu.c pmtu.h struct.h
	gcc -c pmtu.c

file_transfert.o: file_transfert.c file_transfert.h message.h list.h struct.h receive_msg.h
	gcc -c $<

clean:
	rm -f client *.o
