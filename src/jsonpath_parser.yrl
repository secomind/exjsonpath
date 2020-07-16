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

Nonterminals jsonpath path child index union indexes slice filter_expression expression value comparison_operator.
Terminals '.' '..' '*' '$' '[' ']' ',' ':' '@' '?' '(' ')' '>' '>=' '<' '<=' '==' '!=' identifier integer string.
Rootsymbol jsonpath.

jsonpath -> integer : [{access, extract_token('$1')}].
jsonpath -> identifier : [{access, extract_token('$1')}].
jsonpath -> child : '$1'.
jsonpath -> integer path : [{access, extract_token('$1')} | '$2'].
jsonpath -> identifier path : [{access, extract_token('$1')} | '$2'].
jsonpath -> '$' : [].
jsonpath -> '$' path : '$2'.

path -> child : '$1'.
path -> path child : '$1' ++ '$2'.

child -> '..' identifier : [{recurse, extract_token('$2')}].
child -> '..' integer : [{recurse, extract_token('$2')}].
child -> '..' '[' string ']' : [{recurse, extract_token('$3')}].
child -> '..' '[' integer ']' : [{recurse, extract_token('$3')}].
child -> '.' '*' : [wildcard].
child -> '.' identifier : [{access, extract_token('$2')}].
child -> '.' integer : [{access, extract_token('$2')}].
child -> '[' index ']' : ['$2'].
child -> '[' union ']' : ['$2'].

union -> indexes: {union,  '$1'}.
indexes -> index ',' index : ['$1', '$3'].
indexes -> index ',' indexes : ['$1' | '$3'].

index -> integer : {access, extract_token('$1')}.
index -> string : {access, extract_token('$1')}.
index -> slice : '$1'.
index -> filter_expression : {access, '$1'}.

slice -> integer ':' integer ':' integer : {slice, extract_token('$1'), extract_token('$3'), extract_token('$5')}.
slice -> ':' ':' : {slice, 0, last, 1}.
slice -> ':' ':' integer : {slice, 0, last, extract_token('$3')}.
slice -> ':' integer ':' : {slice, 0, extract_token('$2'), 1}.
slice -> ':' integer ':' integer : {slice, 0, extract_token('$2'), extract_token('$4')}.
slice -> integer ':' ':' : {slice, extract_token('$1'), last, 1}.
slice -> integer ':' ':' integer : {slice, extract_token('$1'), last, extract_token('$4')}.
slice -> integer ':' integer ':' : {slice, extract_token('$1'), extract_token('$3'), 1}.

slice -> integer ':' integer : {slice, extract_token('$1'), extract_token('$3'), 1}.
slice -> ':' : {slice, 0, last, 1}.
slice -> ':' integer : {slice, 0, extract_token('$2'), 1}.
slice -> integer ':' : {slice, extract_token('$1'), last, 1}.

filter_expression -> '?' '(' expression ')' : '$3'.

expression -> '@' path comparison_operator value : {'$3', '$2', '$4'}.

value -> string : extract_token('$1').
value -> integer : extract_token('$1').

comparison_operator -> '>' : '>'.
comparison_operator -> '>=' : '>='.
comparison_operator -> '<' : '<'.
comparison_operator -> '<=' : '<='.
comparison_operator -> '==' : '=='.
comparison_operator -> '!=' : '!='.

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
