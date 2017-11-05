Rootsymbol
  template.


Nonterminals
  template
  template_sequence
  template_token
  expr_block
  do_block
  function_block
  if_block
  elseif_block
  else_block
  if_sequence
  if_token
  for_block
  while_block
  code_sequence
  code_token
  string_sequence
  string_token
  heredoc_sequence
  heredoc_token
  ']]'
  '}}'.


Terminals
  text
  '\"'
  '\\"'
  '['
  ']'
  '[['
  '{'
  '}'
  '{{'
  '{{do'
  '{{function'
  '{{if'
  '{{elseif'
  '{{else}}'
  '{{for'
  '{{while'
  '{{end}}'.

% templates

template -> template_sequence :
  "_t = \"\"\n" ++ '$1' ++ "return _t\n".

template_sequence -> '$empty'                         : "".
template_sequence -> template_token template_sequence : '$1' ++ '$2'.

template_token -> '\"'           : literal('$1').
template_token -> '\\"'          : literal('$1').
template_token -> '['            : literal('$1').
template_token -> ']'            : literal('$1').
template_token -> '[['           : literal('$1').
template_token -> '{'            : literal('$1').
template_token -> '}'            : literal('$1').
template_token -> text           : literal('$1').
template_token -> expr_block     : '$1'.
template_token -> do_block       : '$1'.
template_token -> function_block : '$1'.
template_token -> if_block       : '$1'.
template_token -> for_block      : '$1'.
template_token -> while_block    : '$1'.

% simple expression blocks

expr_block -> '{{' code_sequence '}}' :
  "_t = _t .. (tostring(" ++ '$2' ++ "))\n".

% control blocks

do_block -> '{{do' code_sequence '}}' :
  "do " ++ '$2' ++ "\n".

function_block -> '{{function' code_sequence '}}' :
  "function " ++ '$2' ++ "\n".

if_block -> '{{if' code_sequence '}}' if_sequence '{{end}}' :
  "if " ++ '$2' ++ "\n" ++ '$4' ++ "end\n".

elseif_block -> '{{elseif' code_sequence '}}' if_sequence :
  "elseif " ++ '$2' ++ "\n" ++ '$4'.

else_block -> '{{else}}' if_sequence :
  "else" ++ "\n" ++ '$2'.

for_block -> '{{for' code_sequence '}}' template_sequence '{{end}}' :
  "for " ++ '$2' ++ "\n" ++ '$4' ++ "end\n".

while_block -> '{{while' code_sequence '}}' template_sequence '{{end}}' :
  "while " ++ '$2' ++ "\n" ++ '$4' ++ "end\n".

% templates allowed within if/else/elseif

if_sequence -> '$empty'             : "".
if_sequence -> if_token if_sequence : '$1' ++ '$2'.

if_token -> template_token : '$1'.
if_token -> elseif_block   : '$1'.
if_token -> else_block     : '$1'.

% lua code expressions

code_sequence -> code_token               : '$1'.
code_sequence -> code_token code_sequence : '$1' ++ '$2'.

code_token -> text                       : value('$1').
code_token -> '\"' string_sequence '\"'  : value('$1') ++ '$2' ++ value('$3').
code_token -> '[' code_sequence ']'      : value('$1') ++ '$2' ++ value('$3').
code_token -> '[[' heredoc_sequence ']]' : value('$1') ++ '$2' ++ value('$3').
code_token -> '{' '}'                    : value('$1') ++ value('$2').
code_token -> '{{' '}}'                  : value('$1') ++ value('$2').
code_token -> '{' code_sequence '}'      : value('$1') ++ '$2' ++ value('$3').
code_token -> '{{' code_sequence '}}'    : value('$1') ++ '$2' ++ value('$3').

string_sequence -> '$empty'                     : "".
string_sequence -> string_token string_sequence : '$1' ++ '$2'.

string_token -> '\\"'        : value('$1').
string_token -> '['          : value('$1').
string_token -> ']'          : value('$1').
string_token -> '[['         : value('$1').
string_token -> '{'          : value('$1').
string_token -> '}'          : value('$1').
string_token -> '{{'         : value('$1').
string_token -> '{{do'       : value('$1').
string_token -> '{{function' : value('$1').
string_token -> '{{if'       : value('$1').
string_token -> '{{elseif'   : value('$1').
string_token -> '{{else}}'   : value('$1').
string_token -> '{{for'      : value('$1').
string_token -> '{{while'    : value('$1').
string_token -> '{{end}}'    : value('$1').
string_token -> text         : value('$1').

heredoc_sequence -> '$empty'                       : "".
heredoc_sequence -> heredoc_token heredoc_sequence : '$1' ++ '$2'.

heredoc_token -> '\"'         : value('$1').
heredoc_token -> '\\"'        : value('$1').
heredoc_token -> '{'          : value('$1').
heredoc_token -> '}'          : value('$1').
heredoc_token -> '{{'         : value('$1').
heredoc_token -> '{{do'       : value('$1').
heredoc_token -> '{{function' : value('$1').
heredoc_token -> '{{if'       : value('$1').
heredoc_token -> '{{elseif'   : value('$1').
heredoc_token -> '{{else}}'   : value('$1').
heredoc_token -> '{{for'      : value('$1').
heredoc_token -> '{{while'    : value('$1').
heredoc_token -> '{{end}}'    : value('$1').
heredoc_token -> text         : value('$1').

% primitives

']]' -> ']' ']' : "]]".
'}}' -> '}' '}' : "}}".


Erlang code.

value({_,_,V}) -> V;
value(V) -> V.

literal({_,_,V}) -> literal(V);
literal(V) -> "_t = _t .. [[" ++ V ++ "]]\n".
