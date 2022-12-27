defmodule Cbor do
  @moduledoc """
  Documentation for `Cbor`.
  """

  @mt0 <<0::3>>
  @mt1 <<1::3>>
  @mt2 <<2::3>>
  @mt3 <<3::3>>
  @mt4 <<4::3>>
  @mt5 <<5::3>>
  @mt6 <<6::3>>
  @mt7 <<7::3>>

  defguard valid_info(info, len) when 24 <= info and info <= 27 and len >= info - 23
  defguard is_not_well_formed(info) when 28 <= info and info <= 31

  def decode(<<@mt0, info::5>>) when info < 24, do: {:ok, info}
  def decode(<<@mt0, info::5, rest::binary>>) when valid_info(info, byte_size(rest)) do
    length = Integer.pow(2, info - 24)
    value = rest
      |> binary_part(0, length)
      |> :binary.decode_unsigned
    {:ok, value}
  end
  def decode(<<_::3, info::5, _>>) when is_not_well_formed(info), do: {:error, :not_well_formed}
end
