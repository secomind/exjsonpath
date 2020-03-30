#
# This file is part of ExJsonPath.
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

defmodule ExJsonPath.Parser do
  use ExUnit.Case

  test "parse already tokenized simple json path" do
    tokens = [{:"$", 1}, {:., 1}, {:identifier, 1, "hello"}, {:., 1}, {:identifier, 1, "world"}]

    assert :jsonpath_parser.parse(tokens) == {:ok, [access: "hello", access: "world"]}
  end

  test "tokenize and parse simple json path" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$.hello.world')
    assert :jsonpath_parser.parse(tokens) == {:ok, [access: "hello", access: "world"]}
  end

  test "tokenize and parse simple json with braket notation" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$[\'hello\'][\'world\']')
    assert :jsonpath_parser.parse(tokens) == {:ok, [access: "hello", access: "world"]}
  end

  test "tokenize and parse path with arrays" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$.data[0].values[-1].value')

    assert :jsonpath_parser.parse(tokens) ==
             {:ok, [access: "data", access: 0, access: "values", access: -1, access: "value"]}
  end

  test "tokenize and parse complex path" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$.data[0].values[?(@.name == "test")].value')

    assert :jsonpath_parser.parse(tokens) ==
             {:ok,
              [
                access: "data",
                access: 0,
                access: "values",
                access: {:==, [access: "name"], "test"},
                access: "value"
              ]}
  end

  test "tokenize and parse union with 2 indexes" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$.values[1,"a"].value')

    assert :jsonpath_parser.parse(tokens) ==
             {:ok,
              [
                access: "values",
                union: [access: 1, access: "a"],
                access: "value"
              ]}
  end

  test "tokenize and parse union with 3 indexes" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$.values[1,"a",2].value')

    assert :jsonpath_parser.parse(tokens) ==
             {:ok,
              [
                access: "values",
                union: [access: 1, access: "a", access: 2],
                access: "value"
              ]}
  end

  test "tokenize and parse union with filter" do
    {:ok, tokens, _} = :jsonpath_lexer.string('$.values[1,?(@.a > 1)].value')

    assert :jsonpath_parser.parse(tokens) ==
             {:ok,
              [
                access: "values",
                union: [access: 1, access: {:>, [access: "a"], 1}],
                access: "value"
              ]}
  end

  describe "tokenize and parse slice operator" do
    test "1:2" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[1:2]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 1, 2, 1}]}
    end

    test "1:2:3" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[1:2:3]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 1, 2, 3}]}
    end

    test ":" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[:]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 0, :last, 1}]}
    end

    test ":1" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[:1]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 0, 1, 1}]}
    end

    test "1:" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[1:]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 1, :last, 1}]}
    end

    test "::" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[::]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 0, :last, 1}]}
    end

    test "::2" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[::2]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 0, :last, 2}]}
    end

    test ":2:" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[:2:]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 0, 2, 1}]}
    end

    test ":2:3" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[:2:3]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 0, 2, 3}]}
    end

    test "2::" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[2::]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 2, :last, 1}]}
    end

    test "2::2" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[2::2]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 2, :last, 2}]}
    end

    test "2:2:" do
      {:ok, tokens, _} = :jsonpath_lexer.string('$.values[2:2:]')

      assert :jsonpath_parser.parse(tokens) == {:ok, [{:access, "values"}, {:slice, 2, 2, 1}]}
    end
  end
end
