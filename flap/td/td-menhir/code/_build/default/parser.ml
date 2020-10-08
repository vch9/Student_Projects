
(* This generated code requires the following version of MenhirLib: *)

let () =
  MenhirLib.StaticVersion.require_20190626

module MenhirBasics = struct
  
  exception Error
  
  type token = 
    | SUM
    | STAR
    | RPAREN
    | PLUS
    | LPAREN
    | INT of (
# 5 "parser.mly"
      (int)
# 21 "parser.ml"
  )
    | ID of (
# 6 "parser.mly"
      (string)
# 26 "parser.ml"
  )
    | EOF
  
end

include MenhirBasics

let _eRR =
  MenhirBasics.Error

# 1 "parser.mly"
   (* Emacs, open this with -*- tuareg -*- *)
open AST

# 41 "parser.ml"

module Tables = struct
  
  include MenhirBasics
  
  let token2terminal : token -> int =
    fun _tok ->
      match _tok with
      | EOF ->
          8
      | ID _ ->
          7
      | INT _ ->
          6
      | LPAREN ->
          5
      | PLUS ->
          4
      | RPAREN ->
          3
      | STAR ->
          2
      | SUM ->
          1
  
  and error_terminal =
    0
  
  and token2value : token -> Obj.t =
    fun _tok ->
      match _tok with
      | EOF ->
          Obj.repr ()
      | ID _v ->
          Obj.repr _v
      | INT _v ->
          Obj.repr _v
      | LPAREN ->
          Obj.repr ()
      | PLUS ->
          Obj.repr ()
      | RPAREN ->
          Obj.repr ()
      | STAR ->
          Obj.repr ()
      | SUM ->
          Obj.repr ()
  
  and default_reduction =
    (4, "\000\000\005@\000\t `\000q\b")
  
  and error =
    (9, "G\002\000H\228p\000\000\191G?\209\192\000\000\128\000\142G\b\000\000\000\b\000")
  
  and start =
    1
  
  and action =
    ((8, "\030\b\020\030\030\000\000\014\030\003\030\000\000\030\000\030\030 \000\000\030\000"), (8, "%*%%%%%%\t\n\t\"\t\t\t\t\006\014:J\018\022\026W"))
  
  and lhs =
    (4, "\004C32\017")
  
  and goto =
    ((8, "\003\000\000\006\014\000\000\000\022\000.\000\000\000\000\030&\000\000\000\000\000"), (8, "\b\020\n\021\b\000\n\016\b\000\n\014\b\000\n\r\b\000\n\017\b\000\n\018\012\000\n"))
  
  and semantic_action =
    [|
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _;
          MenhirLib.EngineTypes.semv = e;
          MenhirLib.EngineTypes.startp = _startpos_e_;
          MenhirLib.EngineTypes.endp = _endpos_e_;
          MenhirLib.EngineTypes.next = {
            MenhirLib.EngineTypes.state = _;
            MenhirLib.EngineTypes.semv = _2;
            MenhirLib.EngineTypes.startp = _startpos__2_;
            MenhirLib.EngineTypes.endp = _endpos__2_;
            MenhirLib.EngineTypes.next = {
              MenhirLib.EngineTypes.state = _menhir_s;
              MenhirLib.EngineTypes.semv = t;
              MenhirLib.EngineTypes.startp = _startpos_t_;
              MenhirLib.EngineTypes.endp = _endpos_t_;
              MenhirLib.EngineTypes.next = _menhir_stack;
            };
          };
        } = _menhir_stack in
        let e : (AST.exp) = Obj.magic e in
        let _2 : unit = Obj.magic _2 in
        let t : (AST.exp) = Obj.magic t in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_t_ in
        let _endpos = _endpos_e_ in
        let _v : (AST.exp) = 
# 20 "parser.mly"
(
  Add (t, e)
)
# 142 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = t;
          MenhirLib.EngineTypes.startp = _startpos_t_;
          MenhirLib.EngineTypes.endp = _endpos_t_;
          MenhirLib.EngineTypes.next = _menhir_stack;
        } = _menhir_stack in
        let t : (AST.exp) = Obj.magic t in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_t_ in
        let _endpos = _endpos_t_ in
        let _v : (AST.exp) = 
# 24 "parser.mly"
(
  t
)
# 169 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = x;
          MenhirLib.EngineTypes.startp = _startpos_x_;
          MenhirLib.EngineTypes.endp = _endpos_x_;
          MenhirLib.EngineTypes.next = _menhir_stack;
        } = _menhir_stack in
        let x : (
# 6 "parser.mly"
      (string)
# 190 "parser.ml"
        ) = Obj.magic x in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_x_ in
        let _endpos = _endpos_x_ in
        let _v : (AST.exp) = 
# 38 "parser.mly"
(
  Id x
)
# 200 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = x;
          MenhirLib.EngineTypes.startp = _startpos_x_;
          MenhirLib.EngineTypes.endp = _endpos_x_;
          MenhirLib.EngineTypes.next = _menhir_stack;
        } = _menhir_stack in
        let x : (
# 5 "parser.mly"
      (int)
# 221 "parser.ml"
        ) = Obj.magic x in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_x_ in
        let _endpos = _endpos_x_ in
        let _v : (AST.exp) = 
# 42 "parser.mly"
(
  LInt x
)
# 231 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _;
          MenhirLib.EngineTypes.semv = _3;
          MenhirLib.EngineTypes.startp = _startpos__3_;
          MenhirLib.EngineTypes.endp = _endpos__3_;
          MenhirLib.EngineTypes.next = {
            MenhirLib.EngineTypes.state = _;
            MenhirLib.EngineTypes.semv = e;
            MenhirLib.EngineTypes.startp = _startpos_e_;
            MenhirLib.EngineTypes.endp = _endpos_e_;
            MenhirLib.EngineTypes.next = {
              MenhirLib.EngineTypes.state = _menhir_s;
              MenhirLib.EngineTypes.semv = _1;
              MenhirLib.EngineTypes.startp = _startpos__1_;
              MenhirLib.EngineTypes.endp = _endpos__1_;
              MenhirLib.EngineTypes.next = _menhir_stack;
            };
          };
        } = _menhir_stack in
        let _3 : unit = Obj.magic _3 in
        let e : (AST.exp) = Obj.magic e in
        let _1 : unit = Obj.magic _1 in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos__1_ in
        let _endpos = _endpos__3_ in
        let _v : (AST.exp) = 
# 46 "parser.mly"
(
  e
)
# 272 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _;
          MenhirLib.EngineTypes.semv = _7;
          MenhirLib.EngineTypes.startp = _startpos__7_;
          MenhirLib.EngineTypes.endp = _endpos__7_;
          MenhirLib.EngineTypes.next = {
            MenhirLib.EngineTypes.state = _;
            MenhirLib.EngineTypes.semv = e3;
            MenhirLib.EngineTypes.startp = _startpos_e3_;
            MenhirLib.EngineTypes.endp = _endpos_e3_;
            MenhirLib.EngineTypes.next = {
              MenhirLib.EngineTypes.state = _;
              MenhirLib.EngineTypes.semv = e2;
              MenhirLib.EngineTypes.startp = _startpos_e2_;
              MenhirLib.EngineTypes.endp = _endpos_e2_;
              MenhirLib.EngineTypes.next = {
                MenhirLib.EngineTypes.state = _;
                MenhirLib.EngineTypes.semv = e1;
                MenhirLib.EngineTypes.startp = _startpos_e1_;
                MenhirLib.EngineTypes.endp = _endpos_e1_;
                MenhirLib.EngineTypes.next = {
                  MenhirLib.EngineTypes.state = _;
                  MenhirLib.EngineTypes.semv = x;
                  MenhirLib.EngineTypes.startp = _startpos_x_;
                  MenhirLib.EngineTypes.endp = _endpos_x_;
                  MenhirLib.EngineTypes.next = {
                    MenhirLib.EngineTypes.state = _;
                    MenhirLib.EngineTypes.semv = _2;
                    MenhirLib.EngineTypes.startp = _startpos__2_;
                    MenhirLib.EngineTypes.endp = _endpos__2_;
                    MenhirLib.EngineTypes.next = {
                      MenhirLib.EngineTypes.state = _menhir_s;
                      MenhirLib.EngineTypes.semv = _1;
                      MenhirLib.EngineTypes.startp = _startpos__1_;
                      MenhirLib.EngineTypes.endp = _endpos__1_;
                      MenhirLib.EngineTypes.next = _menhir_stack;
                    };
                  };
                };
              };
            };
          };
        } = _menhir_stack in
        let _7 : unit = Obj.magic _7 in
        let e3 : (AST.exp) = Obj.magic e3 in
        let e2 : (AST.exp) = Obj.magic e2 in
        let e1 : (AST.exp) = Obj.magic e1 in
        let x : (
# 6 "parser.mly"
      (string)
# 333 "parser.ml"
        ) = Obj.magic x in
        let _2 : unit = Obj.magic _2 in
        let _1 : unit = Obj.magic _1 in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos__1_ in
        let _endpos = _endpos__7_ in
        let _v : (AST.exp) = 
# 50 "parser.mly"
(
  Sum (x, e1, e2 ,e3)
)
# 345 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _;
          MenhirLib.EngineTypes.semv = _2;
          MenhirLib.EngineTypes.startp = _startpos__2_;
          MenhirLib.EngineTypes.endp = _endpos__2_;
          MenhirLib.EngineTypes.next = {
            MenhirLib.EngineTypes.state = _menhir_s;
            MenhirLib.EngineTypes.semv = e;
            MenhirLib.EngineTypes.startp = _startpos_e_;
            MenhirLib.EngineTypes.endp = _endpos_e_;
            MenhirLib.EngineTypes.next = _menhir_stack;
          };
        } = _menhir_stack in
        let _2 : unit = Obj.magic _2 in
        let e : (AST.exp) = Obj.magic e in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_e_ in
        let _endpos = _endpos__2_ in
        let _v : (
# 9 "parser.mly"
      (AST.exp)
# 377 "parser.ml"
        ) = 
# 15 "parser.mly"
(
  e
)
# 383 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _;
          MenhirLib.EngineTypes.semv = t;
          MenhirLib.EngineTypes.startp = _startpos_t_;
          MenhirLib.EngineTypes.endp = _endpos_t_;
          MenhirLib.EngineTypes.next = {
            MenhirLib.EngineTypes.state = _;
            MenhirLib.EngineTypes.semv = _2;
            MenhirLib.EngineTypes.startp = _startpos__2_;
            MenhirLib.EngineTypes.endp = _endpos__2_;
            MenhirLib.EngineTypes.next = {
              MenhirLib.EngineTypes.state = _menhir_s;
              MenhirLib.EngineTypes.semv = f;
              MenhirLib.EngineTypes.startp = _startpos_f_;
              MenhirLib.EngineTypes.endp = _endpos_f_;
              MenhirLib.EngineTypes.next = _menhir_stack;
            };
          };
        } = _menhir_stack in
        let t : (AST.exp) = Obj.magic t in
        let _2 : unit = Obj.magic _2 in
        let f : (AST.exp) = Obj.magic f in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_f_ in
        let _endpos = _endpos_t_ in
        let _v : (AST.exp) = 
# 29 "parser.mly"
(
  Mul (f, t)
)
# 424 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
      (fun _menhir_env ->
        let _menhir_stack = _menhir_env.MenhirLib.EngineTypes.stack in
        let {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = f;
          MenhirLib.EngineTypes.startp = _startpos_f_;
          MenhirLib.EngineTypes.endp = _endpos_f_;
          MenhirLib.EngineTypes.next = _menhir_stack;
        } = _menhir_stack in
        let f : (AST.exp) = Obj.magic f in
        let _endpos__0_ = _menhir_stack.MenhirLib.EngineTypes.endp in
        let _startpos = _startpos_f_ in
        let _endpos = _endpos_f_ in
        let _v : (AST.exp) = 
# 33 "parser.mly"
(
  f
)
# 451 "parser.ml"
         in
        {
          MenhirLib.EngineTypes.state = _menhir_s;
          MenhirLib.EngineTypes.semv = Obj.repr _v;
          MenhirLib.EngineTypes.startp = _startpos;
          MenhirLib.EngineTypes.endp = _endpos;
          MenhirLib.EngineTypes.next = _menhir_stack;
        });
    |]
  
  and trace =
    None
  
end

module MenhirInterpreter = struct
  
  module ET = MenhirLib.TableInterpreter.MakeEngineTable (Tables)
  
  module TI = MenhirLib.Engine.Make (ET)
  
  include TI
  
  module Symbols = struct
    
    type _ terminal = 
      | T_error : unit terminal
      | T_SUM : unit terminal
      | T_STAR : unit terminal
      | T_RPAREN : unit terminal
      | T_PLUS : unit terminal
      | T_LPAREN : unit terminal
      | T_INT : (
# 5 "parser.mly"
      (int)
# 487 "parser.ml"
    ) terminal
      | T_ID : (
# 6 "parser.mly"
      (string)
# 492 "parser.ml"
    ) terminal
      | T_EOF : unit terminal
    
    type _ nonterminal = 
      | N_term : (AST.exp) nonterminal
      | N_phrase : (
# 9 "parser.mly"
      (AST.exp)
# 501 "parser.ml"
    ) nonterminal
      | N_factor : (AST.exp) nonterminal
      | N_exp : (AST.exp) nonterminal
    
  end
  
  include Symbols
  
  include MenhirLib.InspectionTableInterpreter.Make (Tables) (struct
    
    include TI
    
    include Symbols
    
    include MenhirLib.InspectionTableInterpreter.Symbols (Symbols)
    
    let terminal =
      fun t ->
        match t with
        | 0 ->
            X (T T_error)
        | 1 ->
            X (T T_SUM)
        | 2 ->
            X (T T_STAR)
        | 3 ->
            X (T T_RPAREN)
        | 4 ->
            X (T T_PLUS)
        | 5 ->
            X (T T_LPAREN)
        | 6 ->
            X (T T_INT)
        | 7 ->
            X (T T_ID)
        | 8 ->
            X (T T_EOF)
        | _ ->
            assert false
    
    and nonterminal =
      fun nt ->
        match nt with
        | 4 ->
            X (N N_exp)
        | 3 ->
            X (N N_factor)
        | 2 ->
            X (N N_phrase)
        | 1 ->
            X (N N_term)
        | _ ->
            assert false
    
    and lr0_incoming =
      (8, "\000\004\012\016\012\014\016\003\n\007\006\003\t\t\b\t\t\t\b\005\t\018")
    
    and rhs =
      ((8, "\005\003\n\t\003\016\014\012\t\b\004\012\016\t\t\t\b\t\018\007\006\003\007"), (8, "\000\001\004\005\006\007\n\017\019\022\023"))
    
    and lr0_core =
      (8, "\000\001\002\003\004\005\006\007\b\t\n\011\012\r\014\015\016\017\018\019\020\021")
    
    and lr0_items =
      ((16, "\000\000\003\001\003\002\003\003\002\129\002\001\001\129\001\001\000\129\000\130\004\129\004\001\004\002\004\003\000\131\002\130\002\131\003\004\003\005\003\006\003\007\000\001\003\129\003\130"), (8, "\000\001\002\003\004\005\006\007\t\n\012\r\014\015\016\017\018\019\020\021\022\023\024"))
    
    and nullable =
      "\000"
    
    and first =
      (9, "G#\145\200\228p")
    
  end) (ET) (TI)
  
end

let phrase =
  fun lexer lexbuf ->
    (Obj.magic (MenhirInterpreter.entry 0 lexer lexbuf) : (
# 9 "parser.mly"
      (AST.exp)
# 583 "parser.ml"
    ))

module Incremental = struct
  
  let phrase =
    fun initial_position ->
      (Obj.magic (MenhirInterpreter.start 0 initial_position) : (
# 9 "parser.mly"
      (AST.exp)
# 593 "parser.ml"
      ) MenhirInterpreter.checkpoint)
  
end

# 269 "/home/valentin/.opam/default/lib/menhir/standard.mly"
  

# 601 "parser.ml"
