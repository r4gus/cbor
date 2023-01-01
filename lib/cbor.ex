defmodule Cbor do
  @moduledoc """
  Documentation for `Cbor`.
  """

  @unsigned 0
  @signed 1
  @bytestr 2
  @textstr 3
  @arr 4
  @map 5
  @tag 6
  @simple 7

  defguard valid_info?(info) when info <= 27

  def decode(<<data::binary>>) do
    case head(data) do
      {@unsigned, _, value, rest} -> {:ok, value, rest}
      {@signed, _, value, rest} -> {:ok, -1 - value, rest}
      {@simple, info, value, rest} -> decode(@simple, info, rest, value)
      {major_type, _, value, rest} -> decode(major_type, rest, value)
    end
  end

  def encode(data) when is_integer(data) and data >= 0 do
    case data do
      x when x in 0..23 -> <<x::8>>
      x when x in 24..255 -> <<24::8, x::8>>
      x when x in 256..65535 -> <<25::8, x::16>>
      x when x in 65535..4294967295 -> <<26::8, x::32>>
      x when x in 4294967296..18446744073709551615 -> <<27::8, x::64>>
    end
  end
  def encode(data) when is_integer(data) and data < 0 do
    <<_::3, info::5, data::binary>> = encode(-(data + 1))
    <<1::3, info::5, data::binary>>
  end

  defp decode(@bytestr, <<data::binary>>, length), do: decode(3, data, length)
  defp decode(@textstr, <<data::binary>>, length) when byte_size(data) >= length do
    {lhs, rhs} = String.split_at(data, length)
    {:ok, lhs, rhs}
  end
  defp decode(@textstr, <<_::binary>>, _length), do: {:error, :insufficient_data}

  defp decode(@arr, <<data::binary>>, 0), do: {:ok, [], data}
  defp decode(@arr, <<data::binary>>, count) do
    case decode(data) do
      {:ok, data_item, rest} -> case decode(@arr, rest, count - 1) do
        {:ok, array, rest} -> {:ok, [data_item | array], rest}
        {:error, error} -> {:error, error}
      end
      {:error, error} -> {:error, error}
    end
  end

  defp decode(@map, <<data::binary>>, 0), do: {:ok, %{}, data}
  defp decode(@map, <<data::binary>>, count) do
    case decode(data) do
      {:ok, key, key_rest} -> case decode(key_rest) do
         {:ok, value, value_rest} -> case decode(@map, value_rest, count - 1) do
            {:ok, map, rest} -> {:ok, Map.merge(map, %{key => value}), rest}
            {:error, error} -> {:error, error}
         end
         {:error, error} -> {:error, error}
      end
      {:error, error} -> {:error, error}
    end
  end

  defp decode(@tag, <<data::binary>>, tag) do
    case decode(data) do
      {:ok, content, rest} -> {:ok, {tag, content}, rest}
      {:error, error} -> {:error, error}
    end
  end

  defp decode(@simple, info, <<data::binary>>, value) do
    case info do
      x when x in 0..19 -> {:ok, value, data}
      20 -> {:ok, false, data}
      21 -> {:ok, true, data}
      22 -> {:ok, :null, data}
      23 -> {:ok, :undefined, data}
      24 -> {:ok, value, data}
      25 -> {:ok, decode_half(<<value::16>>), data}
      26 -> {:ok, decode_single(<<value::32>>), data}
      27 -> {:ok, decode_double(<<value::64>>), data}
      x when x in 28..31 -> {:error, "not well-formed simple value (#{info})"}
      _ -> {:ok, value, data}
    end
  end

  defp head(<<mt::3, 24::5, value::8, data::binary>>), do: {mt, 24, value, data}
  defp head(<<mt::3, 25::5, value::16, data::binary>>), do: {mt, 25, value, data}
  defp head(<<mt::3, 26::5, value::32, data::binary>>), do: {mt, 26, value, data}
  defp head(<<mt::3, 27::5, value::64, data::binary>>), do: {mt, 27, value, data}
  defp head(<<mt::3, info::5, data::binary>>) when valid_info?(info), do: {mt, info, info, data}
  defp head(<<mt::8, _::binary>>), do: {:error, "malformed head #{mt}"}
  defp head(<<>>), do: {:error, "unexpected end of input"}

  defp decode_half(<<half::float-size(16)>>), do: half
  defp decode_half(<<_::1, exp::5, mant::10, _::binary>>) when exp == 31, do: if mant == 0, do: :infinity, else: :nan
  defp decode_single(<<single::float-size(32)>>), do: single
  defp decode_single(<<_::1, exp::8, mant::23, _::binary>>) when exp == 255, do: if mant == 0, do: :infinity, else: :nan
  defp decode_double(<<double::float-size(64)>>), do: double
  defp decode_double(<<_::1, exp::11, mant::52, _::binary>>) when exp == 2047, do: if mant == 0, do: :infinity, else: :nan
end
