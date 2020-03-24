#
# This file is part of ExJsonPath.
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

defmodule ExJsonPath do
  @moduledoc """
  This module implements a JSONPath evaluator.
  """

  alias ExJsonPath.ParsingError

  @opaque compiled_path :: list({:access, String.t()})

  @doc """
  Evaluate JSONPath on given input.

  Returns `{:ok, [result1 | results]}` on success, {:error, %ExJsonPath.ParsingError{}} otherwise.

  ## Examples

    iex> ExJsonPath.eval(%{"a" => %{"b" => 42}}, "$.a.b")
    {:ok, [42]}

    iex> ExJsonPath.eval([%{"v" => 1}, %{"v" => 2}, %{"v" => 3}], "$[?(@.v > 1)].v")
    {:ok, [2, 3]}

    iex> ExJsonPath.eval(%{"a" => %{"b" => 42}}, "$.x.y")
    {:ok, []}
  """
  @spec eval(term(), String.t() | compiled_path()) ::
          {:ok, list(term())} | {:error, ParsingError.t()}
  def eval(input, jsonpath)

  def eval(input, path) when is_binary(path) do
    with {:ok, compiled} <- compile(path) do
      eval(input, compiled)
    end
  end

  def eval(input, compiled_path) when is_list(compiled_path) do
    recurse(input, compiled_path)
  end

  @doc """
  Parse and compile a path.

  Returns a {:ok, compiled_path} on success, {:error, reason} otherwise.
  """
  @spec compile(String.t()) :: {:ok, compiled_path()} | {:error, ParsingError.t()}
  def compile(path) when is_binary(path) do
    with charlist = String.to_charlist(path),
         {:ok, tokens, _} <- :jsonpath_lexer.string(charlist),
         {:ok, compiled} <- :jsonpath_parser.parse(tokens) do
      {:ok, compiled}
    else
      {:error, {_line, :jsonpath_lexer, error_desc}, _} ->
        message_string =
          error_desc
          |> :jsonpath_lexer.format_error()
          |> List.to_string()

        {:error, %ParsingError{message: message_string}}

      {:error, {_line, :jsonpath_parser, message}} ->
        message_string =
          message
          |> :jsonpath_parser.format_error()
          |> List.to_string()

        {:error, %ParsingError{message: message_string}}
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
