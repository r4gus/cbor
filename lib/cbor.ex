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
      {4, value, rest} -> decode(:arr, rest, value)
      {5, value, rest} -> decode(:map, rest, value)
      {6, value, rest} -> decode(:tag, rest, value)
    end
  end

  defp decode(:str, <<data::binary>>, length) when byte_size(data) >= length do
    {lhs, rhs} = String.split_at(data, length)
    {:ok, lhs, rhs}
  end
  defp decode(:str, <<_::binary>>, _length), do: {:error, :insufficient_data}

  defp decode(:arr, <<data::binary>>, 0), do: {:ok, [], data}
  defp decode(:arr, <<data::binary>>, count) do
    case decode(data) do
      {:ok, data_item, rest} -> case decode(:arr, rest, count - 1) do
        {:ok, array, rest} -> {:ok, [data_item | array], rest}
        {:error, error} -> {:error, error}
      end
      {:error, error} -> {:error, error}
    end
  end

  defp decode(:map, <<data::binary>>, 0), do: {:ok, %{}, data}
  defp decode(:map, <<data::binary>>, count) do
    case decode(data) do
      {:ok, key, key_rest} -> case decode(key_rest) do
         {:ok, value, value_rest} -> case decode(:map, value_rest, count - 1) do
            {:ok, map, rest} -> {:ok, Map.merge(map, %{key => value}), rest}
            {:error, error} -> {:error, error}
         end
         {:error, error} -> {:error, error}
      end
      {:error, error} -> {:error, error}
    end
  end

  defp decode(:tag, <<data::binary>>, tag) do
    case decode(data) do
      {:ok, content, rest} -> {:ok, {tag, content}, rest}
      {:error, error} -> {:error, error}
    end
  end

  defp head(<<mt::3, 24::5, value::8, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, 25::5, value::16, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, 26::5, value::32, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, 27::5, value::64, data::binary>>), do: {mt, value, data}
  defp head(<<mt::3, info::5, data::binary>>) when valid_info?(info), do: {mt, info, data}
  defp head(<<mt::8, _::binary>>), do: {:error, "malformed head #{mt}"}
  defp head(<<>>), do: {:error, "unexpected end of input"}
end
