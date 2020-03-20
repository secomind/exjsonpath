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

defmodule ExJsonPathTest do
  use ExUnit.Case
  doctest ExJsonPath

  test "eval $.hello.world" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world"

    assert ExJsonPath.eval(map, path) == {:ok, ["test"]}
  end

  test "eval $.hello.world.this.is.missing doesn't match" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world.this.is.missing"

    assert ExJsonPath.eval(map, path) == {:error, :no_match}
  end

  test "eval $.hello[0] on an object doesn't match" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello[0]"

    assert ExJsonPath.eval(map, path) == {:error, :no_match}
  end

  test "eval $.hello.world[0] on a string doesn't match" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world[0]"

    assert ExJsonPath.eval(map, path) == {:error, :no_match}
  end

  # goessner's implementation (and others) return [["test"]] here.
  # Few other implementations will return ["test"].
  # Here we behave like goessner's one.
  test "eval $.hello.world returns a single value array" do
    map = %{"hello" => %{"world" => ["test"]}}
    path = "$.hello.world"

    assert ExJsonPath.eval(map, path) == {:ok, [["test"]]}
  end

  test "eval $.data.values[1] returns an array item" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values[1]"

    assert ExJsonPath.eval(map, path) == {:ok, [-1]}
  end

  test "eval $.data.values[4] which causes an out of bonds access" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values[4]"

    assert ExJsonPath.eval(map, path) == {:error, :no_match}
  end

  test "eval $.data.missing[0] on missing key doesn't match" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.missing[0]"

    assert ExJsonPath.eval(map, path) == {:error, :no_match}
  end

  test "eval $.data.values.missing doesn't match" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values.missing"

    assert ExJsonPath.eval(map, path) == {:error, :no_match}
  end

  test "eval $[0] on array root item" do
    array = [10, 11, 12, 13]
    path = "$[0]"

    assert ExJsonPath.eval(array, path) == {:ok, [10]}
  end

  test "eval $.data.values[1].value" do
    map = %{"data" => %{"values" => [%{"value" => 0.1}, %{"value" => 0.2}, %{"value" => 0.3}]}}
    path = "$.data.values[1].value"

    assert ExJsonPath.eval(map, path) == {:ok, [0.2]}
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

    assert ExJsonPath.eval(map, path) == {:ok, [0.3]}
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

    assert ExJsonPath.eval(map, path) == {:ok, [0.0, 0.3]}
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

    assert ExJsonPath.eval(map, path) == {:ok, [[0.0], [0.3]]}
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

    assert ExJsonPath.eval(map, path) == {:ok, [0.3]}
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

    assert ExJsonPath.eval(map, path) == {:ok, [0.1, 0.3]}
  end

  # This is not described [here](https://goessner.net/articles/JsonPath/)
  # but his implementation supports it, and nearly every other implementation.
  test "eval hello" do
    map = %{"hello" => %{"world" => "test"}}
    path = "hello"

    assert ExJsonPath.eval(map, path) == {:ok, [%{"world" => "test"}]}
  end

  # This is not described [here](https://goessner.net/articles/JsonPath/)
  # but his implementation supports it, and nearly every other implementation.
  test "eval hello.world" do
    map = %{"hello" => %{"world" => "test"}}
    path = "hello.world"

    assert ExJsonPath.eval(map, path) == {:ok, ["test"]}
  end

  # Goessner's implementation (and others) do not allow any kind of match on bare values
  test "eval $.test on bare values doesn't match" do
    value = 5
    path = "$.test"

    assert ExJsonPath.eval(value, path) == {:error, :no_match}
  end

  # Goessner's implementation (and others) do not allow any kind of match on bare values
  test "eval $[0] on bare values doesn't match" do
    value = true
    path = "$[0]"

    assert ExJsonPath.eval(value, path) == {:error, :no_match}
  end
end
