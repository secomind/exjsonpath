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

Nonterminals jsonpath path child filter_expression expression value comparison_operator.
Terminals '.' '..' '$' '[' ']' '@' '?' '(' ')' '>' '>=' '<' '<=' '==' '!=' identifier integer string.
Rootsymbol jsonpath.

jsonpath -> integer : [{access, extract_token('$1')}].
jsonpath -> identifier : [{access, extract_token('$1')}].
jsonpath -> child : '$1'.
jsonpath -> integer path : [{access, extract_token('$1')} | '$2'].
jsonpath -> identifier path : [{access, extract_token('$1')} | '$2'].
jsonpath -> '$' path : '$2'.

path -> child : '$1'.
path -> path child : '$1' ++ '$2'.

child -> '..' identifier : [{recurse, extract_token('$2')}].
child -> '..' integer : [{recurse, extract_token('$2')}].
child -> '.' identifier : [{access, extract_token('$2')}].
child -> '.' integer : [{access, extract_token('$2')}].
child -> '[' integer ']' : [{access, extract_token('$2')}].
child -> '[' string ']' : [{access, extract_token('$2')}].
child -> '[' filter_expression ']' : [{access, '$2'}].

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
