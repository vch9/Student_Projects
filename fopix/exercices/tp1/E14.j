.class public E14
.super java/lang/Object

;
; standard initializer
.method public <init>()V
   aload_0
   invokenonvirtual java/lang/Object/<init>()V
   return
.end method

.method public static main([Ljava/lang/String;)V
   .limit stack 3
   .limit locals 2 ;; variable 0 args, variable 1 : t


   ;; int [] t = new int[3]
   bipush 3
   newarray int
   astore 1

   ;; t[1] = 2
   aload 1
   bipush 1
   bipush 2
   iastore

   ;; push System.out sur la pile
   getstatic java/lang/System/out Ljava/io/PrintStream;

   ;; Load sur la pile
   aload 1
   bipush 1
   iaload

   ;; Invoque la méthode virtuelle
   invokevirtual java/io/PrintStream/println(I)V

   return
.end method
