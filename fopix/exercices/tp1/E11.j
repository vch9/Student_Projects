.class public E11
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
   .limit locals 2

   getstatic java/lang/System/out Ljava/io/PrintStream;
   bipush 42
   invokevirtual java/io/PrintStream/println(I)V

   return
.end method
