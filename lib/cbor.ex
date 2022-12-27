defmodule Cbor do
  @moduledoc """
  Documentation for `Cbor`.
  """

  defguard valid_info?(info) when info <= 27

  def decode(<<data::binary>>) do
    case head(data) do
      {0, value, rest} -> {:ok, value, rest}
      {1, value, rest} -> {:ok, -1 - value, rest}
      {2, value, rest} -> decode(:str, rest, value)
      {3, value, rest} -> decode(:str, rest, value)
    end
  end

  defp decode(:str, <<data::binary>>, length) when byte_size(data) >= length, do: {:ok, binary_part(data, 0, length), binary_part(data, length, 0)}
  defp decode(:str, <<_::binary>>, _length), do: {:error, :insufficient_data}

  defp head(<<mt::3, 24::5, value::8, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, 25::5, value::16, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, 26::5, value::32, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, 27::5, value::64, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, info::5, data::binary>>) when valid_info?(info), do: {mt, info, data}
  defp head(<<_::binary>>), do: {:error, :not_well_formed}
end
