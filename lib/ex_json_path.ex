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

defmodule ExJsonPath do
  def eval(input, path) when is_binary(path) do
    with {:ok, compiled} <- compile(path) do
      eval(input, compiled)
    end
  end

  def eval(input, compiled_path) when is_list(compiled_path) do
    recurse(input, compiled_path)
  end

  def compile(path) when is_binary(path) do
    with charlist = String.to_charlist(path),
         {:ok, tokens, _} <- :jsonpath_lexer.string(charlist) do
      :jsonpath_parser.parse(tokens)
    end
  end

  defp recurse(item, []) do
    {:ok, [item]}
  end

  defp recurse(enumerable, [{:access, {op, path, value}} | t])
       when is_list(enumerable) or is_map(enumerable) do
    result =
      Enum.reduce(enumerable, [], fn entry, acc ->
        item =
          case entry do
            {_key, value} -> value
            item -> item
          end

        with {:ok, [value_at_path]} <- recurse(item, path),
             true <- compare(op, value_at_path, value),
             {:ok, [leaf_value]} <- recurse(item, t) do
          [leaf_value | acc]
        else
          {:ok, []} ->
            acc

          false ->
            acc
        end
      end)

    {:ok, Enum.reverse(result)}
  end

  defp recurse(map, [{:access, a} | t]) when is_map(map) do
    case Map.fetch(map, a) do
      {:ok, next_item} -> recurse(next_item, t)
      :error -> {:ok, []}
    end
  end

  defp recurse(array, [{:access, a} | t]) when is_list(array) and is_integer(a) do
    case Enum.fetch(array, a) do
      {:ok, next_item} -> recurse(next_item, t)
      :error -> {:ok, []}
    end
  end

  defp recurse(_any, [{:access, _a} | _t]) do
    {:ok, []}
  end

  defp compare(op, value1, value2) do
    case op do
      :> ->
        value1 > value2

      :>= ->
        value1 >= value2

      :< ->
        value1 < value2

      :<= ->
        value1 <= value2

      :== ->
        value1 == value2

      :!= ->
        value1 != value2
    end
  end
end
