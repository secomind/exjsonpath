#
# This file is part of ExJSONPath.
#
# Copyright 2019 Ispirata Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule ExJSONPath.Lexer do
  use ExUnit.Case

  test "tokenize simple json path" do
    assert :jsonpath_lexer.string('$.hello.world') ==
             {:ok,
              [{:"$", 1}, {:., 1}, {:identifier, 1, "hello"}, {:., 1}, {:identifier, 1, "world"}],
              1}
  end

  test "tokenize complex json path" do
    assert :jsonpath_lexer.string('$.data[0].values[?(@.name == "test")].value') ==
             {:ok,
              [
                {:"$", 1},
                {:., 1},
                {:identifier, 1, "data"},
                {:"[", 1},
                {:integer, 1, 0},
                {:"]", 1},
                {:., 1},
                {:identifier, 1, "values"},
                {:"[", 1},
                {:"?", 1},
                {:"(", 1},
                {:@, 1},
                {:., 1},
                {:identifier, 1, "name"},
                {:==, 1},
                {:string, 1, "test"},
                {:")", 1},
                {:"]", 1},
                {:., 1},
                {:identifier, 1, "value"}
              ], 1}
  end
end
