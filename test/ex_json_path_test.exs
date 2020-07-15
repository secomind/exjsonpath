#
# This file is part of ExJSONPath.
#
# Copyright 2019,2020 Ispirata Srl
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

defmodule ExJSONPathTest do
  use ExUnit.Case
  doctest ExJSONPath

  alias ExJSONPath.ParsingError

  test "eval $.hello.world" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world"

    assert ExJSONPath.eval(map, path) == {:ok, ["test"]}
  end

  test "eval $.hello.world.this.is.missing doesn't match" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world.this.is.missing"

    assert ExJSONPath.eval(map, path) == {:ok, []}
  end

  # there are two Goessner's implementations, one returns [[]], while the other returns [{}]
  # most other implementations return [{}].
  # This implementation will return [{}]
  test "eval $.foo.bar with empty obj. 'bar' returns {}" do
    map = %{"foo" => %{"bar" => %{}}}
    path = "$.foo.bar"

    assert ExJSONPath.eval(map, path) == {:ok, [%{}]}
  end

  test "eval $.hello[0] on an object doesn't match" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello[0]"

    assert ExJSONPath.eval(map, path) == {:ok, []}
  end

  test "eval $.hello.world[0] on a string doesn't match" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world[0]"

    assert ExJSONPath.eval(map, path) == {:ok, []}
  end

  # goessner's implementation (and others) return [["test"]] here.
  # Few other implementations will return ["test"].
  # Here we behave like goessner's one.
  test "eval $.hello.world returns a single value array" do
    map = %{"hello" => %{"world" => ["test"]}}
    path = "$.hello.world"

    assert ExJSONPath.eval(map, path) == {:ok, [["test"]]}
  end

  test "eval $.data.values[1] returns an array item" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values[1]"

    assert ExJSONPath.eval(map, path) == {:ok, [-1]}
  end

  # Goessner's implementation supports this syntax.
  # Also this is required for consistency reasons with .. operator.
  test "eval $.data.values.1 returns an array item" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values.1"

    assert ExJSONPath.eval(map, path) == {:ok, [-1]}
  end

  test "eval $.data.values[4] which causes an out of bonds access" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values[4]"

    assert ExJSONPath.eval(map, path) == {:ok, []}
  end

  test "eval $.data.missing[0] on missing key doesn't match" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.missing[0]"

    assert ExJSONPath.eval(map, path) == {:ok, []}
  end

  test "eval $.data.values.missing doesn't match" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values.missing"

    assert ExJSONPath.eval(map, path) == {:ok, []}
  end

  test "eval $[0] on array root item" do
    array = [10, 11, 12, 13]
    path = "$[0]"

    assert ExJSONPath.eval(array, path) == {:ok, [10]}
  end

  test "eval $.data.values[1].value" do
    map = %{"data" => %{"values" => [%{"value" => 0.1}, %{"value" => 0.2}, %{"value" => 0.3}]}}
    path = "$.data.values[1].value"

    assert ExJSONPath.eval(map, path) == {:ok, [0.2]}
  end

  test ~s{eval $.data[0].values[?(@.name == "test")].value filters an array of objects} do
    map = %{
      "data" => [
        %{
          "values" => [
            %{"value" => 0.1, "name" => "foo"},
            %{"value" => 0.2, "name" => "bar"},
            %{"value" => 0.3, "name" => "test"}
          ]
        }
      ]
    }

    path = ~s{$.data[0].values[?(@.name == "test")].value}

    assert ExJSONPath.eval(map, path) == {:ok, [0.3]}
  end

  test ~s{eval $.data[0].values[?(@.name == "test")].value filters an array with missing keys} do
    map = %{
      "data" => [
        %{
          "values" => [
            %{"value" => 0.0, "name" => "test"},
            %{"name" => "foo"},
            %{"value" => 0.2},
            %{"value" => 0.3, "name" => "test"},
            %{"value" => 0.4, "name" => "bar"}
          ]
        }
      ]
    }

    path = ~s{$.data[0].values[?(@.name == "test")].value}

    assert ExJSONPath.eval(map, path) == {:ok, [0.0, 0.3]}
  end

  test ~s{eval $.data[0].values[?(@.k == "a")].v filters an objects array with array values} do
    map = %{
      "data" => [
        %{
          "values" => [
            %{"v" => [0.0], "k" => "a"},
            %{"k" => "c"},
            %{"v" => [0.2]},
            %{"v" => [0.3], "k" => "a"},
            %{"v" => [0.4], "k" => "b"}
          ]
        }
      ]
    }

    path = ~s{$.data[0].values[?(@.k == "a")].v}

    assert ExJSONPath.eval(map, path) == {:ok, [[0.0], [0.3]]}
  end

  test ~s{eval $.data[0].values[?(@.name == "test")].value filters a map} do
    map = %{
      "data" => [
        %{
          "values" => %{
            "a" => %{"value" => 0.1, "name" => "foo"},
            "b" => %{"value" => 0.2, "name" => "bar"},
            "c" => %{"value" => 0.3, "name" => "test"}
          }
        }
      ]
    }

    path = ~s{$.data[0].values[?(@.name == "test")].value}

    assert ExJSONPath.eval(map, path) == {:ok, [0.3]}
  end

  test ~s{eval $.data[0].values[?(@.name == "test")].value filters a map and returns 2 items} do
    map = %{
      "data" => [
        %{
          "values" => %{
            "a" => %{"value" => 0.1, "name" => "test"},
            "b" => %{"value" => 0.2, "name" => "bar"},
            "c" => %{"value" => 0.3, "name" => "test"}
          }
        }
      ]
    }

    path = ~s{$.data[0].values[?(@.name == "test")].value}

    assert ExJSONPath.eval(map, path) == {:ok, [0.1, 0.3]}
  end

  # This is not described [here](https://goessner.net/articles/JsonPath/)
  # but his implementation supports it, and nearly every other implementation.
  test "eval hello" do
    map = %{"hello" => %{"world" => "test"}}
    path = "hello"

    assert ExJSONPath.eval(map, path) == {:ok, [%{"world" => "test"}]}
  end

  # This is not described [here](https://goessner.net/articles/JsonPath/)
  # but his implementation supports it, and nearly every other implementation.
  test "eval hello.world" do
    map = %{"hello" => %{"world" => "test"}}
    path = "hello.world"

    assert ExJSONPath.eval(map, path) == {:ok, ["test"]}
  end

  # This shortcut is supported by fewer implementations, however I think it must be supported
  # for consistency reasons: "keyname" shortcut is already supported for objects, thefore [index]
  # is a reasonable extension.
  # Goessner's implementation does not support it.
  test "eval [3]" do
    array = [10, 11, 12, 13]
    path = "[3]"

    assert ExJSONPath.eval(array, path) == {:ok, [13]}
  end

  # This is supported by Goessner's implementation and some others.
  test "eval 3" do
    array = [10, 11, 12, 13]
    path = "3"

    assert ExJSONPath.eval(array, path) == {:ok, [13]}
  end

  # This is supported by Goessner's implementation and some others.
  test "eval 1.name" do
    array = [%{"name" => "zero"}, %{"name" => "one"}, %{"name" => "two"}]
    path = "1.name"

    assert ExJSONPath.eval(array, path) == {:ok, ["one"]}
  end

  # The majority of implementations do not support this, however this is a side effect
  # of adding support to "[index]" with minimum changes to our grammar.
  # One notable implementation which supports this syntax is the kubectl JSONPath implementation,
  # hence I think also a lot of people is used to this syntax,
  # which doesn't cause any relevant drawback
  test "eval .key" do
    map = %{"key" => 42}
    path = ".key"

    assert ExJSONPath.eval(map, path) == {:ok, [42]}
  end

  # This is just supported for consistency reasons, since we already support .key
  test "eval .1" do
    map = [0, 10, 20, 30]
    path = ".1"

    assert ExJSONPath.eval(map, path) == {:ok, [10]}
  end

  # Goessner's implementation (and others) do not allow any kind of match on bare values
  test "eval $.test on bare values doesn't match" do
    value = 5
    path = "$.test"

    assert ExJSONPath.eval(value, path) == {:ok, []}
  end

  # Goessner's implementation (and others) do not allow any kind of match on bare values
  test "eval $[0] on bare values doesn't match" do
    value = true
    path = "$[0]"

    assert ExJSONPath.eval(value, path) == {:ok, []}
  end

  # Goessner was not supporting this, however this is handy and supported by most implementations
  # https://cburgmer.github.io/json-path-comparison/results/root.html
  test "eval $" do
    map = %{"a" => %{"b" => 42}}
    path = ~s{$}

    assert ExJSONPath.eval(map, path) == {:ok, [map]}
  end

  describe ".. operator" do
    test "eval $..a on a nested object" do
      map = %{
        "a" => 0,
        "b" => %{
          "a" => 1,
          "b" => %{
            "a" => 2,
            "b" => %{
              "a" => 3,
              "b" => %{
                "a" => 4,
                "b" => %{}
              }
            }
          }
        }
      }

      path = ~s{$..a}

      assert ExJSONPath.eval(map, path) == {:ok, [0, 1, 2, 3, 4]}
    end

    test "eval $..missing on a nested object" do
      map = %{
        "a" => 0,
        "b" => %{
          "a" => 1,
          "b" => %{
            "a" => 2,
            "b" => %{
              "a" => 3,
              "b" => %{
                "a" => 4,
                "b" => %{}
              }
            }
          }
        }
      }

      path = ~s{$..missing}

      assert ExJSONPath.eval(map, path) == {:ok, []}
    end

    test "eval $..b on a nested object" do
      map = %{"a" => 0, "b" => %{"a" => 1, "b" => %{"a" => 2, "b" => %{}}}}
      path = ~s{$..b}

      assert ExJSONPath.eval(map, path) ==
               {:ok, [%{"a" => 1, "b" => %{"a" => 2, "b" => %{}}}, %{"a" => 2, "b" => %{}}, %{}]}
    end

    test "eval $..k on an array" do
      array = [%{"k" => "a"}, %{"k" => "c"}, %{"k" => "b"}]

      path = ~s{$..k}

      assert ExJSONPath.eval(array, path) == {:ok, ["a", "c", "b"]}
    end

    test "eval $..k on an empty array" do
      array = []

      path = ~s{$..k}

      assert ExJSONPath.eval(array, path) == {:ok, []}
    end

    test "eval $..k on an empty object" do
      map = %{}

      path = ~s{$..k}

      assert ExJSONPath.eval(map, path) == {:ok, []}
    end

    test "eval $..2" do
      map = %{
        "a" => [0, 1, 2],
        "b" => %{"c" => [3], "d" => [4, 5, "6"], "e" => %{"f" => [7, 8, [], 10]}}
      }

      path = ~s{$..2}

      assert ExJSONPath.eval(map, path) == {:ok, [2, "6", []]}
    end

    test "eval $..2 on a nested array" do
      array = [1, 2, [5, 6, [7, 8, 9]]]

      path = ~s{$..2}

      assert ExJSONPath.eval(array, path) == {:ok, [[5, 6, [7, 8, 9]], [7, 8, 9], 9]}
    end

    test "eval $..1.x on a nested array" do
      array = [0, [1, [2, %{"x" => "computer"}]]]

      path = ~s{$..1.x}

      assert ExJSONPath.eval(array, path) == {:ok, ["computer"]}
    end

    test "eval $..1.x on a nested array with an array leaf" do
      array = [0, [1, [2, %{"x" => ["test", -1]}]]]

      path = ~s{$..1.x}

      assert ExJSONPath.eval(array, path) == {:ok, [["test", -1]]}
    end
  end

  describe "wildcard operator" do
    test "eval $.*" do
      map = %{"data" => %{"values" => [0, -1, 1, -2]}}

      path = ~s{$.*}

      assert ExJSONPath.eval(map, path) == {:ok, [%{"values" => [0, -1, 1, -2]}]}
    end

    test "eval $[*]" do
      map = %{"data" => %{"values" => [0, -1, 1, -2]}}

      path = ~s{$[*]}

      assert ExJSONPath.eval(map, path) == {:ok, [%{"values" => [0, -1, 1, -2]}]}
    end

    test "eval $.*.values.* on an object" do
      map = %{"data" => %{"values" => [%{"a" => 1}, %{"b" => 2}]}}

      path = ~s{$.*.values.*}

      assert ExJSONPath.eval(map, path) == {:ok, [%{"a" => 1}, %{"b" => 2}]}
    end

    test "eval $.* on an array" do
      array = [%{"a" => 1}, %{"b" => 2}]

      path = ~s{$.*}

      assert ExJSONPath.eval(array, path) == {:ok, [%{"a" => 1}, %{"b" => 2}]}
    end

    test "eval $.*.*.* on an array" do
      array = [%{"a" => %{"x" => 1, "y" => -1}}, %{"b" => %{"x" => -2, "y" => -3, "z" => 0}}]

      path = ~s{$.*.*.*}

      assert ExJSONPath.eval(array, path) == {:ok, [1, -1, -2, -3, 0]}
    end
  end

  describe "union operator" do
    test ~s{eval $.test["a","b","c"]} do
      map = %{"test" => %{"a" => 4, "b" => "hello", "c" => 2}}

      path = ~s{$.test["a","b","c"]}

      assert ExJSONPath.eval(map, path) == {:ok, [4, "hello", 2]}
    end

    test ~s{eval $.test["c","b","a"]} do
      map = %{"test" => %{"a" => 4, "b" => "hello", "c" => 2}}

      path = ~s{$.test["c","b","a"]}

      assert ExJSONPath.eval(map, path) == {:ok, [2, "hello", 4]}
    end

    test ~s{eval $.test["c","c","a"]} do
      map = %{"test" => %{"a" => 4, "b" => "hello", "c" => 2}}

      path = ~s{$.test["c","c","a"]}

      assert ExJSONPath.eval(map, path) == {:ok, [2, 2, 4]}
    end

    test ~s{eval $.test[4,2,0]} do
      map = %{"test" => ["0", "1", "2", "3", "4", "5"]}

      path = ~s{$.test[4,2,0]}

      assert ExJSONPath.eval(map, path) == {:ok, ["4", "2", "0"]}
    end

    test ~s{eval $.test[0,0,?(@.a == "ok")]} do
      map = %{"test" => [%{"b" => "test"}, %{"a" => "foo"}, %{"a" => "ok"}]}

      path = ~s{$.test[0,0,?(@.a == "ok")]}

      assert ExJSONPath.eval(map, path) ==
               {:ok, [%{"b" => "test"}, %{"b" => "test"}, %{"a" => "ok"}]}
    end

    test ~s{eval $.test[0,100,?(@.a == "ok")]} do
      map = %{"test" => [%{"b" => "test"}, %{"a" => "foo"}, %{"a" => "ok"}]}

      path = ~s{$.test[0,100,?(@.a == "ok")]}

      assert ExJSONPath.eval(map, path) == {:ok, [%{"b" => "test"}, %{"a" => "ok"}]}
    end

    test ~s{eval $.test[0,0,?(@.a == "ok")].a} do
      map = %{"test" => [%{"b" => "test"}, %{"a" => "foo"}, %{"a" => "ok"}]}

      path = ~s{$.test[0,0,?(@.a == "ok")].a}

      assert ExJSONPath.eval(map, path) == {:ok, ["ok"]}
    end

    test ~s{eval $.test[0,0,?(@.a == "ok")].z} do
      map = %{"test" => [%{"b" => "test"}, %{"a" => "foo"}, %{"a" => "ok"}]}

      path = ~s{$.test[0,0,?(@.a == "ok")].z}

      assert ExJSONPath.eval(map, path) == {:ok, []}
    end
  end

  describe "slice operator" do
    test ~s{eval $.data[0:5]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[0:5]}

      assert ExJSONPath.eval(map, path) == {:ok, [0, -1, 2, -3, 4]}
    end

    # https://cburgmer.github.io/json-path-comparison/results/array_slice_with_range_of_0.html
    test ~s{eval $.data[0:0] does not return results} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[0:0]}

      assert ExJSONPath.eval(map, path) == {:ok, []}
    end

    test ~s{eval $.data[5:5] does not return results} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[5:5]}

      assert ExJSONPath.eval(map, path) == {:ok, []}
    end

    test ~s{eval $.data[0:1]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[0:1]}

      assert ExJSONPath.eval(map, path) == {:ok, [0]}
    end

    # https://cburgmer.github.io/json-path-comparison/results/array_slice_with_range_of_-1.html
    test ~s{eval $.data[5:1]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[5:1]}

      assert ExJSONPath.eval(map, path) == {:ok, []}
    end

    test ~s{eval $.data[:5]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[:5]}

      assert ExJSONPath.eval(map, path) == {:ok, [0, -1, 2, -3, 4]}
    end

    test ~s{eval $.data[::2]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[::2]}

      assert ExJSONPath.eval(map, path) == {:ok, [0, 2, 4, 6, 8]}
    end

    test ~s{eval $.data[1::2]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[1::2]}

      assert ExJSONPath.eval(map, path) == {:ok, [-1, -3, -5, -7]}
    end

    test ~s{eval $.data[1:3]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[1:3]}

      assert ExJSONPath.eval(map, path) == {:ok, [-1, 2]}
    end

    test ~s{eval $.data[0:2,7:9]} do
      map = %{"data" => [0, -1, 2, -3, 4, -5, 6, -7, 8]}

      path = ~s{$.data[0:2,7:9]}

      assert ExJSONPath.eval(map, path) == {:ok, [0, -1, -7, 8]}
    end
  end

  describe "eval $[?(@.v OPERATOR 1)] expressions" do
    test ~s{with == operator} do
      array = [
        %{"k" => "a", "v" => 0},
        %{"k" => "b", "v" => 1},
        %{"k" => "c", "v" => 1},
        %{"k" => "d", "v" => 0}
      ]

      path = ~s{$[?(@.v == 1)]}

      assert ExJSONPath.eval(array, path) ==
               {:ok, [%{"k" => "b", "v" => 1}, %{"k" => "c", "v" => 1}]}
    end

    test ~s{!= operator} do
      array = [
        %{"k" => "a", "v" => 0},
        %{"k" => "b", "v" => 1},
        %{"k" => "c", "v" => 1},
        %{"k" => "d", "v" => 0}
      ]

      path = ~s{$[?(@.v != 1)]}

      assert ExJSONPath.eval(array, path) ==
               {:ok, [%{"k" => "a", "v" => 0}, %{"k" => "d", "v" => 0}]}
    end

    test ~s{with > operator} do
      array = [
        %{"k" => "a", "v" => 0},
        %{"k" => "b", "v" => 1},
        %{"k" => "c", "v" => 2},
        %{"k" => "d", "v" => 0}
      ]

      path = ~s{$[?(@.v > 1)]}

      assert ExJSONPath.eval(array, path) == {:ok, [%{"k" => "c", "v" => 2}]}
    end

    test ~s{with >= operator} do
      array = [
        %{"k" => "a", "v" => 0},
        %{"k" => "b", "v" => 1},
        %{"k" => "c", "v" => 2},
        %{"k" => "d", "v" => 0}
      ]

      path = ~s{$[?(@.v >= 1)]}

      assert ExJSONPath.eval(array, path) ==
               {:ok, [%{"k" => "b", "v" => 1}, %{"k" => "c", "v" => 2}]}
    end

    test ~s{with < operator} do
      array = [
        %{"k" => "a", "v" => 0},
        %{"k" => "b", "v" => 1},
        %{"k" => "c", "v" => 1},
        %{"k" => "d", "v" => 0}
      ]

      path = ~s{$[?(@.v < 1)]}

      assert ExJSONPath.eval(array, path) ==
               {:ok, [%{"k" => "a", "v" => 0}, %{"k" => "d", "v" => 0}]}
    end

    test ~s{with <= operator} do
      array = [
        %{"k" => "a", "v" => 1},
        %{"k" => "b", "v" => 2},
        %{"k" => "c", "v" => 3},
        %{"k" => "d", "v" => 0}
      ]

      path = ~s{$[?(@.v <= 2)]}

      assert ExJSONPath.eval(array, path) ==
               {:ok, [%{"v" => 1, "k" => "a"}, %{"k" => "b", "v" => 2}, %{"k" => "d", "v" => 0}]}
    end
  end

  describe "parsing error" do
    test ~s{with eval @} do
      map = %{"a" => %{"b" => 42}}
      path = ~s{@}

      assert {:error, %ParsingError{message: "" <> _msg}} = ExJSONPath.eval(map, path)
    end

    test "with invalid expression" do
      map = %{"a" => %{"b" => 42}}
      path = ~s{$[?()]}

      assert {:error, %ParsingError{message: "" <> _msg}} = ExJSONPath.eval(map, path)
    end

    test "with unmatched parenthesis" do
      map = %{"a" => %{"b" => 42}}
      path = ~s{$[?(@.v <= 2]}

      assert {:error, %ParsingError{message: "" <> _msg}} = ExJSONPath.eval(map, path)
    end

    test "with invalid operator" do
      array = []

      path = ~s{$[?(@.v # 2)]}

      assert {:error, %ParsingError{message: "" <> _msg}} = ExJSONPath.eval(array, path)
    end

    test "with unexpected chars" do
      map = %{"a" => %{"b" => 42}}
      path = ~s{ùùù}

      assert {:error, %ParsingError{message: "" <> _msg}} = ExJSONPath.eval(map, path)
    end
  end
end
