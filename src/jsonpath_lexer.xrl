%
% This file is part of ExJsonPath.
%
% Copyright 2019 Ispirata Srl
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%

Definitions.

WHITESPACE = [\s\t\n\r]
IDENTIFIER  = [^'".*0-9()$?,>=<\-\:\@\[\]\s\t\n\r][^'".*()$?,>=<\-\:\@\[\]\s\t\n\r]*
INTEGER = \-?[0-9]+
STRING = \"[^"]*\"
LSTRING = \'[^']*\'

Rules.

{WHITESPACE}+ : skip_token.
{IDENTIFIER}  : {token, {identifier,  TokenLine, unicode:characters_to_binary(TokenChars)}}.
{INTEGER}  : {token, {integer,  TokenLine, list_to_integer(TokenChars)}}.
{STRING}  : {token, {string,  TokenLine, string_to_binary(TokenChars)}}.
{LSTRING}  : {token, {string,  TokenLine, string_to_binary(TokenChars)}}.
\$            : {token, {'$',  TokenLine}}.
\@            : {token, {'@',  TokenLine}}.
\.\.          : {token, {'..',  TokenLine}}.
\.            : {token, {'.',  TokenLine}}.
\*            : {token, {'*',  TokenLine}}.
\[            : {token, {'[',  TokenLine}}.
\]            : {token, {']',  TokenLine}}.
\,            : {token, {',',  TokenLine}}.
\:            : {token, {':',  TokenLine}}.
\?            : {token, {'?',  TokenLine}}.
\(            : {token, {'(',  TokenLine}}.
\)            : {token, {')',  TokenLine}}.


\>            : {token, {'>',  TokenLine}}.
\>\=            : {token, {'>=',  TokenLine}}.
\<            : {token, {'<',  TokenLine}}.
\<\=            : {token, {'<=',  TokenLine}}.
\=\=            : {token, {'==',  TokenLine}}.
\!\=            : {token, {'!=',  TokenLine}}.

Erlang code.

string_to_binary(TokenChars) ->
    L1 = lists:droplast(TokenChars),
    [_ | L2] = L1,
    list_to_binary(L2).
