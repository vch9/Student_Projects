#include "meta.h"

//creation d'un fichier au format tif via librairie libtiff

short save_TIFF(SDL_Surface *surf, char const * dst){//utilisation de la libraire extern "libtiff"
  int width=surf->w;
  int heigth=surf->h;
  int sampleperpixel=surf->format->BytesPerPixel;
  TIFF * out=TIFFOpen(dst,"w");
  char *image = malloc(width*heigth*sampleperpixel);
  image=surf->pixels;
  TIFFSetField (out, TIFFTAG_IMAGEWIDTH, width);
  TIFFSetField(out, TIFFTAG_IMAGELENGTH, heigth);
  TIFFSetField(out, TIFFTAG_SAMPLESPERPIXEL, sampleperpixel);
  TIFFSetField(out, TIFFTAG_BITSPERSAMPLE, 8);
  TIFFSetField(out, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
  TIFFSetField(out, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
  TIFFSetField(out, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
  tsize_t linebytes=surf->pitch;
  unsigned char * buf=NULL;
  if (TIFFScanlineSize(out)*linebytes){
    buf =(unsigned char *)_TIFFmalloc(linebytes);
  }
  else{
    buf = (unsigned char *)_TIFFmalloc(TIFFScanlineSize(out));
  }
  TIFFSetField(out, TIFFTAG_ROWSPERSTRIP, TIFFDefaultStripSize(out, width*sampleperpixel));
  for (uint32 row = 0; row < heigth; row++){
    memcpy(buf, &image[(row)*linebytes], linebytes);
    if (TIFFWriteScanline(out, buf, row, 0) < 0){
      printf(" tiff break for\n" );
      break;
    }
  }
  (void) TIFFClose(out);
  if (buf){
    _TIFFfree(buf);
  }


  return 1;
}

void aux(SDL_Surface * s , const char * dst){
  IMG_SaveJPG(s,"tmp.jpeg",QUALITY);
  SDL_Surface * surf = IMG_Load("tmp.jpeg");
  save_TIFF(surf,dst);
  remove("tmp.jpeg");
}


  void export(SDL_Surface * image, const char * path){
    char * pg = malloc(sizeof(char)*15);
    memcpy(pg,".jpeg", sizeof(".jpeg"));
    char * pn = malloc(sizeof(char)*15);
    memcpy(pn, ".png", sizeof(".png"));
    char * bm = malloc(sizeof(char)*15);
    memcpy(bm, ".bmp",sizeof(".bmp"));
    if(strstr(path , pg) != NULL ){
      IMG_SaveJPG(image,path,QUALITY);
    }else if ( strstr(path, pn)!= NULL ){
      IMG_SavePNG(image, path);
    }else if(strstr(path,bm)!= NULL ){
      SDL_SaveBMP(image,path);
    }else{ //dernier format d'export : .tiff
      aux(image,path);
    }
  }



void load(char *const path,SDL_Renderer* renderer, SDL_Surface* onScreen){
  //pas de spécification de type nécéssaire
  SDL_Surface* image = IMG_Load(path);
  //on met a jour la fenetre avec la nouvelle image dedans
  if(image){
  	SDL_Rect rect = { 0, 0, image->w, image->h};
  	SDL_BlitSurface(image, NULL, onScreen, &rect);
  	putOnRenderer(renderer, onScreen);
  }
}
// int main(int argc, char const *argv[]) {
//   SDL_Surface* image = IMG_Load("pictures/galere.bmp");
//   printf("hauteur :%d\n",image->h );
//   printf("largeur :%d\n", image->w );
//   printf("BytesPerPixel :%d\n",image->format->BytesPerPixel );
//   printf("pitch :%d\n",image->pitch );
//   // export(image,argv[1]);
//   // save_TIFF(image,"titeuf.tiff");
//   char * t = malloc(sizeof(char)*20);
//   memcpy(t,"poulet.tiff",sizeof("poulet.tiff"));
//   export(image,t);
//   // save_TIFF(image,t);
//   printf("bonjpour\n" );
//   return 0;
// }
