#include "man.h"

#define MAX_MAN 17
char* man[] = {"man/draw/fill.txt", "man/draw/replace.txt", "man/draw/shades_of_grey.txt", "man/draw/black_and_white.txt", "man/draw/negatif.txt",
"man/select/select.txt",
"man/transform/copy.txt", "man/transform/cut.txt", "man/transform/paste.txt", "man/transform/resize.txt", "man/transform/symetrie.txt", "man/transform/trim.txt", "man/transform/rotation.txt"
"man/meta/open.txt", "man/meta/exit.txt", "man/meta/load.txt", "man/meta/export.txt"
};
void afficher_man(int index);

int nonTermHelp(char* tokens[], int* p, int size){
	if(strncmp(tokens[*p], "help", sizeof("help"))!=0) return 0;
	*p += 1;
	if(*p>=size){
		afficher_man(-1);
		return 1;
	}
	if(strncmp(tokens[*p], "fill", sizeof("fill"))==0){
		afficher_man(0);
	}
	else if(strncmp(tokens[*p], "replace", sizeof("replace"))==0){
		afficher_man(1);
	}
	else if(strncmp(tokens[*p], "shades_of_grey", sizeof("shades_of_grey"))==0){
		afficher_man(2);
	}
	else if(strncmp(tokens[*p], "black_and_white", sizeof("black_and_white"))==0){
		afficher_man(3);
	}
	else if(strncmp(tokens[*p], "negatif", sizeof("negatif"))==0){
		afficher_man(4);
	}
	else if(strncmp(tokens[*p], "select", sizeof("select"))==0){
		afficher_man(5);
	}
	else if(strncmp(tokens[*p], "copy", sizeof("copy"))==0){
		afficher_man(6);
	}
	else if(strncmp(tokens[*p], "cut", sizeof("cut"))==0){
		afficher_man(7);
	}
	else if(strncmp(tokens[*p], "paste", sizeof("paste"))==0){
		afficher_man(8);
	}
	else if(strncmp(tokens[*p], "resize", sizeof("resize"))==0){
		afficher_man(9);
	}
	else if(strncmp(tokens[*p], "symetrie", sizeof("symetrie"))==0){
		afficher_man(10);
	}
	else if(strncmp(tokens[*p], "trim", sizeof("trim"))==0){
		afficher_man(11);
	}
	else if(strncmp(tokens[*p], "rotation", sizeof("rotation"))==0){
		afficher_man(12);
	}
	else if(strncmp(tokens[*p], "open", sizeof("open"))==0){
		afficher_man(13);
	}
	else if(strncmp(tokens[*p], "exit", sizeof("exit"))==0){
		afficher_man(14);
	}
	else if(strncmp(tokens[*p], "load", sizeof("load"))==0){
		afficher_man(15);
	}
	else if(strncmp(tokens[*p], "export", sizeof("export"))==0){
		afficher_man(16);
	}
	else{
		printf("Help inconnue\n");
	}

	return 1;
}

void afficher_man(int index){
	if(index==-1){ /* On affiche tout */
		for(int i=0; i<MAX_MAN; i++)
			afficher_man(i);
		return;
	}
	if(index<0 || index>MAX_MAN) return;
	FILE* f = NULL;
	f = fopen(man[index], "r");

	if(f){
		char buf[4096];
		memset(buf, 0, 4096);
		int offset = 0;
		int n;
		while(1){
			if(offset<4096){
				n = fread(buf+offset, 1, 4096-offset, f);
				if(n<=0) break;
			}
		}
		printf("%s", buf);
		fclose(f);
	}
}