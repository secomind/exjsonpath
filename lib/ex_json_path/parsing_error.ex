#
# This file is part of ExJsonPath.
#
# Copyright 2020 Ispirata Srl
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

defmodule ExJsonPath.ParsingError do
  @moduledoc """
  Describes a JSONPath parsing error.
  message contains the user readable error message.
  """

  @keys [
    :message
  ]

  @enforce_keys @keys

  defstruct @keys

  @type t() :: %__MODULE__{
          message: String.t()
        }
end
