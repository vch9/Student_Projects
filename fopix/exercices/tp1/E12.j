.class public E12
.super java/lang/Object

;
; standard initializer
.method public <init>()V
   aload_0
   invokenonvirtual java/lang/Object/<init>()V
   return
.end method

.method public static main([Ljava/lang/String;)V
   .limit stack 2
   .limit locals 2 ;; variable 0 args, variable 1 : x


   ;; int x = 1 - 2 + 5
   bipush 1
   bipush 2
   isub
   bipush 5
   iadd
   istore 1

   ;; push System.out sur la pile
   getstatic java/lang/System/out Ljava/io/PrintStream;

   ;; Load sur la pile
   iload 1

   ;; Invoque la méthode virtuelle
   invokevirtual java/io/PrintStream/println(I)V

   return
.end method
