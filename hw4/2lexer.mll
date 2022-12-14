{
  open Lexing
  open Parser
  open Range
  
  exception Lexer_error of Range.t * string

  let reset_lexbuf (filename:string) (lnum:int) lexbuf : unit =
    lexbuf.lex_curr_p <- {
      pos_fname = filename;
      pos_cnum = 0;
      pos_bol = 0;
      pos_lnum = lnum;
    }

  let newline lexbuf =
    lexbuf.lex_curr_p <- { (lexeme_end_p lexbuf) with
      pos_lnum = (lexeme_end_p lexbuf).pos_lnum + 1;
      pos_bol = (lexeme_end lexbuf) }
    
  (* Boilerplate to define exceptional cases in the lexer. *)
  let unexpected_char lexbuf (c:char) : 'a =
    raise (Lexer_error (Range.lex_range lexbuf,
        Printf.sprintf "Unexpected character: '%c'" c))


(* 
    CHECK all of the binary operations except +, -, *, and ==
    CHECK the boolean type and values
    default-initialized and implicitly-initialized array expressions and array global initializers
    string literal expressions and global initializers
    CHECK for loops
 *)
  (* Lexing reserved words *)
  let reserved_words = [
  (* Keywords *)
  ("null", NULL);
  ("void", TVOID);
  ("int", TINT);
  ("string", TSTRING);
  ("else", ELSE);
  ("if", IF);
  ("while", WHILE);
  ("return", RETURN);
  ("var", VAR);
  ("global", GLOBAL);
  (* For loops *)
  ("for", FOR);
  (* Bools *)
  ("true", TRUE);
  ("false", FALSE);

  ("new", NEW);

  (* Symbols *)
  ( ";", SEMI);
  ( ",", COMMA);
  ( "{", LBRACE);
  ( "}", RBRACE);
  ( "+", PLUS);
  ( "-", DASH);
  ( "*", STAR);
  ( "!", BANG);
  ( "~", TILDE);
  ( "(", LPAREN);
  ( ")", RPAREN);
  ( "[", LBRACKET);
  ( "]", RBRACKET);
  (* Missing bin ops *)
  ( "!=", NEQ);
  ( "&", LAND);
  ( "[&]", BAND);
  ( "|", LOR);
  ( "[|]", BOR);

  (* Compare *)
  ( "=", EQ);
  ( "==", EQEQ);
  ( "<", LESS);
  ( "<=", LESSEQ);
  ( ">", GREAT);
  ( ">=", GREATEQ);

  (* Shift ops *)
  ( ">>", LRSHIFT);
  ( ">>>", ARSHIFT);
  ( "<<", LLSHIFT);
  
  ]

let (symbol_table : (string, Parser.token) Hashtbl.t) = Hashtbl.create 1024
  let _ =
    List.iter (fun (str,t) -> Hashtbl.add symbol_table str t) reserved_words

  let maybe_char = ref '0'

  let create_token lexbuf =
    let str = lexeme lexbuf in 
    try (Hashtbl.find symbol_table str) 
    with _ -> match maybe_char with
         | {contents = '0'} -> IDENT str
         | {contents = c} ->
           maybe_char := '0';
           IDENT (String.make 1 c ^ str)

  (* Lexing comments and strings *)
  let string_buffer = ref (Bytes.create 2048)
  let string_end = ref 0
  let start_lex = ref (Range.start_of_range Range.norange)

  let start_pos_of_lexbuf lexbuf : pos =
    (Range.pos_of_lexpos (lexeme_start_p lexbuf))

  let lex_long_range lexbuf : Range.t =
    let end_p = lexeme_end_p lexbuf in
    mk_range end_p.pos_fname (!start_lex) (pos_of_lexpos end_p)  

  let reset_str () = string_end := 0

  let add_str ch =
    let x = !string_end in
    let buffer = !string_buffer
    in
      if x = Bytes.length buffer then
        begin
          let new_buffer = Bytes.create (x*2) in
          Bytes.blit buffer 0 new_buffer 0 x;
          Bytes.set new_buffer x ch;
          string_buffer := new_buffer;
          string_end := x+1
        end
      else
        begin
          Bytes.set buffer x ch;
          string_end := x+1
        end

  let get_str () = Bytes.sub_string (!string_buffer) 0 (!string_end)

  (* Lexing directives *)
  let lnum = ref 1
  let mode = ref 0
  let counter= ref 0
  let scounter = ref 0
}

(* Declare your aliases (let foo = regex) and rules here. *)
let newline = '\n' | ('\r' '\n') | '\r'
let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let character = uppercase | lowercase
let whitespace = ['\t' ' ']
let digit = ['0'-'9']
let hexdigit = ['0'-'9'] | ['a'-'f'] | ['A'-'F']

(* Boolean can be these *)
let boolean = "false" | "true"

(* Arrayes *)
let intarr = "int"(whitespace)*"[]"
let stringarr = "string"(whitespace)*"[]"
let boolarr = "bool"(whitespace)*"[]"

rule token = parse
  | eof { EOF }
  | "/*" { start_lex := start_pos_of_lexbuf lexbuf; comments 0 lexbuf }
  | '"' { reset_str(); start_lex := start_pos_of_lexbuf lexbuf; string false lexbuf }
  | '#' { let p = lexeme_start_p lexbuf in
          if p.pos_cnum - p.pos_bol = 0 then directive 0 lexbuf 
          else raise (Lexer_error (lex_long_range lexbuf,
            Printf.sprintf "# can only be the 1st char in a line.")) }
  | "{" { if !mode = 0 then 
    begin reset_str(); counter := (!counter+1); start_lex := start_pos_of_lexbuf lexbuf; 
      array Ast.TInt 0 [] lexbuf 
    end
    else begin scounter:=(!scounter+1); create_token lexbuf end}
  | "}" 
    {if !mode <> 0 then begin
      scounter:= (!scounter-1); create_token lexbuf 
    end 
    else begin
      counter:=(!counter-1); if !counter = 0 then mode:=1; create_token lexbuf
    end}
  | lowercase (digit | character | '_')* { create_token lexbuf }
  | digit+ | "0x" hexdigit+ { INT (Int64.of_string (lexeme lexbuf)) }
  | whitespace+ { token lexbuf }
  | newline { newline lexbuf; token lexbuf }
  
  | intarr {mode:=1; TARRAY(multiarray ( Ast.TInt) lexbuf)} 
  | boolarr {mode:=1; TARRAY(multiarray ( Ast.TBool) lexbuf)} 
  | stringarr {mode:=1; TARRAY(multiarray ( (Ast.TRef (Ast.RString))) lexbuf)} 
  

  | "var" {mode:=1; VAR}
  | "global" {mode:=1; GLOBAL}
  | "int" {mode:=1; TINT}
  | "string" {mode:=1; TSTRING}
  | "bool" {mode:=1; TBOOL}
  | "void" {mode:=1; TVOID}
  
  | "new" {mode:= 1; create_token lexbuf}
  | "if" {mode:= 1; create_token lexbuf}
  | "while" {mode:= 1; create_token lexbuf}
  | "for" {mode:= 1; create_token lexbuf}

  | ';' | ',' | '{' | '}' | '+' | '-' | '*' | '=' | "==" 
  | "!=" | '!' | '~' | '(' | ')' | '[' | ']' | '&' | '|' 
  | '<' | "<=" | '>' | ">=" | "<<" | ">>" | ">>>" | "[&]"
  | "[|]"
    { create_token lexbuf }

  | _ as c { unexpected_char lexbuf c }

and multiarray ty = parse
  | whitespace+ { ty } 
  | "[]" {multiarray 
    ( (Ast.TRef (Ast.RArray ty))) lexbuf}
  | "[" {ty}
  | _ as c {maybe_char := c; ty}

and array ty level lst = parse
  | '}' {ARRAY(lst)}
  | '{' {array level (List.append lst [(Ast.no_loc
  (Ast.CArr Ast.TInt (arrays Ast.TInt (level+1) [] lexbuf)))]) lexbuf}
  | whitespace+ { array Ast.TInt level lst lexbuf}
  | ',' { array Ast.TInt level lst lexbuf}
  | "null" {array Ast.TInt level (List.append lst [(Ast.no_loc
  (Ast.CNull))]) lexbuf}
  | boolean {array Ast.TBool level (List.append lst [(Ast.no_loc
  (Ast.CBool(bool_of_string(lexeme lexbuf))))]) lexbuf}
  | digit+ { array Ast.TInt level (List.append lst [(Ast.no_loc
  (Ast.CInt(Int64.of_string(lexeme lexbuf))))]) lexbuf} 
  | '"' { reset_str(); start_lex := start_pos_of_lexbuf lexbuf;
  array Ast.TInt level (List.append lst [(Ast.no_loc (str false lexbuf))]) lexbuf}
  | newline { newline lexbuf; array Ast.TInt level lst lexbuf }
  | _ {print_string (lexeme lexbuf); ARRAY (lst)}


and arrays ty level lst = parse
  | '}' {lst}
  | '{' {arrays Ast.TInt level (List.append lst [(Ast.no_loc
  (Ast.CArr(arrays Ast.TInt (level+1) [] lexbuf)))]) lexbuf}
  | whitespace+ { arrays Ast.TInt level lst lexbuf}
  | ',' { arrays Ast.TInt level lst lexbuf}
  | "null" {arrays Ast.TInt level (List.append lst [(Ast.no_loc
  (Ast.CNull))]) lexbuf}
  | boolean {arrays Ast.Bool level (List.append lst [(Ast.no_loc
  (Ast.CBool(bool_of_string(lexeme lexbuf))))]) lexbuf}
  | digit+ { arrays Ast.TInt level (List.append lst [(Ast.no_loc
  (Ast.CInt(Int64.of_string(lexeme lexbuf))))]) lexbuf}
  | '"' { reset_str(); start_lex := start_pos_of_lexbuf lexbuf;
  arrays Ast.TInt level (List.append lst [(Ast.no_loc (str false lexbuf))]) lexbuf}
  | newline { newline lexbuf; arrays Ast.TInt level lst lexbuf }
  | _ {lst}

and directive state = parse
  | whitespace+ { directive state lexbuf } 
  | digit+ { if state = 0 then 
               (lnum := int_of_string (lexeme lexbuf); 
                directive 1 lexbuf)
             else if state = 2 then directive 3 lexbuf
             else raise (Lexer_error (lex_long_range lexbuf,
               Printf.sprintf "Illegal directives")) }
  | '"' { if state = 1 then
            begin
              reset_str(); 
              start_lex := start_pos_of_lexbuf lexbuf; 
              string true lexbuf
            end 
          else raise (Lexer_error (lex_long_range lexbuf,
            Printf.sprintf "Illegal directives")) 
         }
  | newline { if state = 2 || state = 3 then
                begin 
                  reset_lexbuf (get_str()) !lnum lexbuf;
                  token lexbuf
                end 
              else raise (Lexer_error (lex_long_range lexbuf,
                Printf.sprintf "Illegal directives")) }
  | _ { raise (Lexer_error (lex_long_range lexbuf, 
          Printf.sprintf "Illegal directives")) }


and comments level = parse
  | "*/" { if level = 0 then token lexbuf
	   else comments (level-1) lexbuf }
  | "/*" { comments (level+1) lexbuf}
  | [^ '\n'] { comments level lexbuf }
  | "\n" { newline lexbuf; comments level lexbuf }
  | eof	 { raise (Lexer_error (lex_long_range lexbuf,
             Printf.sprintf "comments are not closed")) }

and string in_directive = parse
  | '"'  { if in_directive = false then
             STRING (get_str())
           else directive 2 lexbuf }  
  | '\\' { add_str(escaped lexbuf); string in_directive lexbuf }
  | '\n' { add_str '\n'; newline lexbuf; string in_directive lexbuf }
  | eof  { raise (Lexer_error (lex_long_range lexbuf,
             Printf.sprintf "String is not terminated")) }
  | _    { add_str (Lexing.lexeme_char lexbuf 0); string in_directive lexbuf }

and escaped = parse
  | 'n'    { '\n' }
  | 't'    { '\t' }
  | '\\'   { '\\' }
  | '"'    { '\034'  }
  | '\''   { '\'' }
  | ['0'-'9']['0'-'9']['0'-'9']
    {
      let x = int_of_string(lexeme lexbuf) in
      if x > 255 then
        raise (Lexer_error (lex_long_range lexbuf,
          (Printf.sprintf "%s is an illegal escaped character constant" (lexeme lexbuf))))
      else
        Char.chr x
    }
  | [^ '"' '\\' 't' 'n' '\'']
    { raise (Lexer_error (lex_long_range lexbuf,
        (Printf.sprintf "%s is an illegal escaped character constant" (lexeme lexbuf) ))) }


