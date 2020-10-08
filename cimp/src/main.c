#include <readline/readline.h>
#include "thread.h"

#define LINE_SIZE 1024

int isEnded = 0;

/*Ce thread ne s'occupe que de traiter les commandes entrées dans le shell
 * Le thread "pricipal" se trouve dans thread.c*/
int main(int argc, char *argv[]) {

    SDL_Init(SDL_INIT_VIDEO);

    SDL_Thread *thread;

    /*
     * Initialisation de la struct contenant les paramètres
     * struct mainParameterBlock{
            SDL_bool isEnded;
            SDL_bool hasNewCommand;
            char *command;
        };
        C'est paramètres vont être passé au thread comme variables partagées
     * */
    mainParameterBlock *parameterBlock = malloc(sizeof(mainParameterBlock));
    parameterBlock->isEnded = SDL_FALSE;
    parameterBlock->command = malloc(LINE_SIZE);
    parameterBlock->hasNewCommand = SDL_FALSE;

    thread = SDL_CreateThread(startThread, "thread", parameterBlock);

    while (!parameterBlock->isEnded) {

        /* 1 - On recupère l'input de l'utilisateur (la commande) dans le thread principal
         * 2 - On copie la command dans la variable partagée
         * 3 - On met à jour le tag "hasNewCommand" pour informer le second thread qu'il peut traiter la commande*/
        char *tmp;
        tmp = readline(">>");

        parameterBlock->hasNewCommand = SDL_TRUE;
        strcpy(parameterBlock->command, tmp);

        free(tmp);
    }
    //parameterBlock->isEnded = SDL_TRUE;
    free(parameterBlock);
    SDL_WaitThread(thread, &isEnded);
    SDL_Quit();
    return 1;

}
