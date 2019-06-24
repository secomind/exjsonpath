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

  test "eval a simple path" do
    map = %{"hello" => %{"world" => "test"}}
    path = "$.hello.world"

    assert ExJsonPath.eval(map, path) == "test"
  end

  test "eval a simple path with array" do
    map = %{"data" => %{"values" => [0, -1, 1, -2]}}
    path = "$.data.values[1]"

    assert ExJsonPath.eval(map, path) == -1
  end

  test "eval a simple path with array and a further object" do
    map = %{"data" => %{"values" => [%{"value" => 0.1}, %{"value" => 0.2}, %{"value" => 0.3}]}}
    path = "$.data.values[1].value"

    assert ExJsonPath.eval(map, path) == 0.2
  end

  test "eval a path with access to a filtered array" do
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

    assert ExJsonPath.eval(map, path) == [0.3]
  end

  test "eval a path with access to a filtered map" do
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

    assert ExJsonPath.eval(map, path) == [0.3]
  end

  test "eval a path with access to a filtered map and multiple results" do
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

    assert ExJsonPath.eval(map, path) == [0.1, 0.3]
  end
end
