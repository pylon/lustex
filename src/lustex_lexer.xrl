Definitions.

S = [\s\t\n]

Rules.

"                        : {token, {'\"', TokenLine, TokenChars}}.
\\"                      : {token, {'\\"', TokenLine, TokenChars}}.
\[                       : {token, {'[', TokenLine, TokenChars}}.
\]                       : {token, {']', TokenLine, TokenChars}}.
\[\[                     : {token, {'[[', TokenLine, TokenChars}}.
{                        : {token, {'{', TokenLine, TokenChars}}.
}                        : {token, {'}', TokenLine, TokenChars}}.
{{                       : {token, {'{{', TokenLine, TokenChars}}.
{{{S}*do{S}+             : {token, {'{{do', TokenLine, TokenChars}}.
{{{S}*function{S}+       : {token, {'{{function', TokenLine, TokenChars}}.
{{{S}*if{S}+             : {token, {'{{if', TokenLine, TokenChars}}.
{{{S}*elseif{S}+         : {token, {'{{elseif', TokenLine, TokenChars}}.
{{{S}*else{S}*}}         : {token, {'{{else}}', TokenLine, TokenChars}}.
{{{S}*for{S}+            : {token, {'{{for', TokenLine, TokenChars}}.
{{{S}*while{S}+          : {token, {'{{while', TokenLine, TokenChars}}.
{{{S}*end{S}*}}          : {token, {'{{end}}', TokenLine, TokenChars}}.
([^{}"\[\]\\]|(\\[^"]))+ : {token, {text, TokenLine, TokenChars}}.

Erlang code.
