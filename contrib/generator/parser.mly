
%{
open Printf

let _ = Parsing.set_trace false;;
let debugprint = ref false;;
let classname  = ref "";;

let set_classname str = classname := str;;
let print str = if !debugprint then print_endline str;;

let includee = Hashtbl.create 20;;
(* let _ = Hashtbl.replace includee "" "";; *)

let do_include str =
  Hashtbl.replace includee str str;;
(*  Hashtbl.iter (fun k _ -> print_endline k) includee;; *)

let get_includee() =
  Hashtbl.fold (fun k _ l -> k::l) includee [];;

let parse_error s = print ("parse_error->"^s);;
%}

%token VOID INT CHAR
%token CONST
%token NAMESPACE_SEPARATOR
%token RRBRACE LRBRACE COMMA SEMICOLON
%token RBRACE LBRACE
%token RBRACE2 LBRACE2
%token EOF COMMENT
%token QUOTE
%token CLASS CONST
%token PUBLIC PRIVATE
%token REFERENCE
%token <string> LITERAL
%token <string> DECORATOR
%token <string> CODE
%token <string> INCLUDE
%token <string> DESTRUCTOR

%start input
%type <(string list * Stree.class_impl list)> input

%%

input: 
          exp0 { print "exp0";
		 (*		 print_int (Hashtbl.length includee); List.iter print_endline (get_includee()); *)
		 (get_includee(), $1) }
        | input exp0		{
	  print "input exp0";
	  let (includes, classes) = $1 in
	  let classes0 = $2 in
	  ( includes, (classes @ classes0)) }
;

exp0:
	  one_class      { print ">hage"; [$1] }
	| one_class exp0 { print ">one_class exp0"; $1 :: $2 }
	| INCLUDE LBRACE LITERAL RBRACE exp0   { do_include $3; print ("including " ^ $3); $5 }
;


one_class:
	CLASS LITERAL LBRACE2 exp SEMICOLON {
	  print ">CLASS LITERAL LBRACE2 exp SEMICOLON"; 
	  set_classname $2;
	  let (funcs,members) = $4 in
	  Stree.ClassImpl($2, funcs, members)
	}
;
exp:
	  PUBLIC exp { $2 }
        | PRIVATE exp { $2 }
        | declaration     { print ">declaration"; ([$1], []) }
        | declaration exp { print ">declaration exp"; let (funs,mems) = $2 in ( $1 :: funs, mems ) }
        | member          { ([], [$1]) }
        | member exp      { let (funs,mems) = $2 in ( funs , $1 :: mems) }
	| RBRACE2         { ([], []) }
;

member:   anytype LITERAL SEMICOLON   { ($1, $2) }
;

declaration:
	| DECORATOR declaration
	    { print ">dec1"; let (t,n,arg,decs,c,b) = $2 in (t,n,arg, $1::decs, c, b) }

	  /* maybe constructor */
	| LITERAL LRBRACE RRBRACE CODE SEMICOLON {
	  print $1;
	  (Stree.Constructor, $1, [], [], $4, false)
	}
	| LITERAL LRBRACE argv RRBRACE CODE SEMICOLON {
	  print $1;
	  (Stree.Constructor, $1, $3, [], $5, false)
	}
	  /* destructor */
	| DESTRUCTOR LRBRACE RRBRACE CODE SEMICOLON {
	  print $1;
	  (Stree.Destructor, $1, [], [], $4, false)
	}
	| DESTRUCTOR LRBRACE argv RRBRACE CODE SEMICOLON {
	  print $1;
	  (Stree.Destructor, $1, $3, [], $5, false)
	}

	  /* methods */
	| anytype LITERAL LRBRACE RRBRACE CONST CODE SEMICOLON
	    { print ">dec3"; ($1, $2, [], [], $6, true) }
	| anytype LITERAL LRBRACE argv RRBRACE CONST CODE SEMICOLON
	    { print ">dec4"; ($1, $2, $4, [], $7, true) }
	| anytype LITERAL LRBRACE RRBRACE CODE SEMICOLON
	    { print ">dec3"; ($1, $2, [], [], $5, false) }
	| anytype LITERAL LRBRACE argv RRBRACE CODE SEMICOLON
	    { print ">dec4"; ($1, $2, $4, [], $6, false) }
;

argv:    anytype LITERAL            { print ">anytype LITERAL"; [($1, (Stree.make_symbol $2))] }
	|anytype LITERAL COMMA argv { print ">anytype LITERAL COMMA argv"; ($1, (Stree.make_symbol $2)) :: $4 }
;

anytypes:anytype                  { print ">anytypes"; [$1] }
	|anytype COMMA anytypes   { $1 :: $3 }
;

anytype: CONST anytype                  { print ">const "; $2 }
	|LITERAL                        { print ">anytype: LITERAL"; Stree.make_anytype $1 false}
	|LITERAL REFERENCE              { print ">anytype: LITERAL"; Stree.make_anytype $1 true}
	|LITERAL LBRACE anytypes RBRACE { Stree.make_template $1 $3 false}
	|LITERAL LBRACE anytypes RBRACE REFERENCE { Stree.make_template $1 $3 true}
;

%%
