

#include "thread.h"

mainParameterBlock *pBlock;
void manageEvents(mainParameterBlock *pBlock);

int startThread(void *p) {
    mainParameterBlock * block = pBlock= (mainParameterBlock*)p;
    /*C'est une solution comme une autre pour avoir un terminal indépendant de la fenêtre*/
    while (!block->isEnded) {

        //gestion de l'event
        manageEvents(block);
        if(block && block->hasNewCommand){
            //C'est ici qu'on gère les commandes de l'utilisateur

            block->hasNewCommand=SDL_FALSE;
            exec(block->command);
        }

    }

    return 1;
}

void threadExit() {
    pBlock->isEnded=SDL_TRUE;
    printf("Appuyez sur Enter");
}
void refreshFocusedWindowByID(Uint32 winID);
void setBackGround(int w, int h);
void manageEvents(mainParameterBlock *pBlock) {
    SDL_Event event;
    SDL_PollEvent(&event);
    switch (event.type) {
        SDL_Window* window;
        case SDL_WINDOWEVENT:
            switch (event.window.event) {
                case SDL_WINDOWEVENT_TAKE_FOCUS:
                    refreshFocusedWindowByID(event.window.windowID);
                    break;
                case SDL_WINDOWEVENT_CLOSE:
                    window = SDL_GetWindowFromID(event.window.windowID);
                    SDL_DestroyWindow(window);
                    break;
                case SDL_WINDOWEVENT_RESIZED:
                    window = SDL_GetWindowFromID(event.window.windowID);
                    int w, h;
                    SDL_GetWindowSize(window, &w, &h);
                    setBackGround(w,h);

                    break;
            }
    }

}
