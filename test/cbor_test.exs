defmodule CborTest do
  use ExUnit.Case
  doctest Cbor

  test "decode integer smaller 24" do
    assert Cbor.decode(<<0>>) == {:ok, 0, <<>>}
    assert Cbor.decode(<<1>>) == {:ok, 1, <<>>}
    assert Cbor.decode(<<0xa>>) == {:ok, 10, <<>>}
    assert Cbor.decode(<<0x17>>) == {:ok, 23, <<>>}
    assert Cbor.decode(<<0x20>>) == {:ok, -1, <<>>}
    assert Cbor.decode(<<0x29>>) == {:ok, -10, <<>>}
  end

  test "decode integer that fits in one byte" do
    assert Cbor.decode(<<0x18, 0x18>>) == {:ok, 24, <<>>}
    assert Cbor.decode(<<0x18, 0x19>>) == {:ok, 25, <<>>}
    assert Cbor.decode(<<0x18, 0x64>>) == {:ok, 100, <<>>}
    assert Cbor.decode(<<0x38, 0x63>>) == {:ok, -100, <<>>}
  end

  test "decode integer that fits in two bytes" do
    assert Cbor.decode(<<0x19, 0x03, 0xe8>>) == {:ok, 1000, <<>>}
    assert Cbor.decode(<<0x39, 0x03, 0xe7>>) == {:ok, -1000, <<>>}
  end

  test "decode integer that fits in four bytes" do
    assert Cbor.decode(<<0x1a, 0x00, 0x0f, 0x42, 0x40>>) == {:ok, 1000000, <<>>}
  end

  test "decode integer that fits in eight bytes" do
    assert Cbor.decode(<<0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00>>) == {:ok, 1000000000000, <<>>}
    assert Cbor.decode(<<0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff>>) == {:ok, 18446744073709551615, <<>>}
    assert Cbor.decode(<<0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff>>) == {:ok, -18446744073709551616, <<>>}
  end

  test "decode byte string" do
    assert Cbor.decode(<<0x40>>) == {:ok, <<>>, <<>>}
    assert Cbor.decode(<<0x44, 0x01, 0x02, 0x03, 0x04>>) == {:ok, <<0x01, 0x02, 0x03, 0x04>>, <<>>}
  end

  test "decode text string" do
    assert Cbor.decode(<<0x61, 0x61>>) == {:ok, "a", <<>>}
    assert Cbor.decode(<<0x64, 0x49, 0x45, 0x54, 0x46>>) == {:ok, "IETF", <<>>}
    assert Cbor.decode(<<0x62, 0x22, 0x5c>>) == {:ok, "\"\\", <<>>}
    assert Cbor.decode(<<0x62, 0xc3, 0xbc>>) == {:ok, "\u00fc", <<>>}
    assert Cbor.decode(<<0x63, 0xe6, 0xb0, 0xb4>>) == {:ok, "\u6c34", <<>>}
    assert Cbor.decode(<<0x64, 0x49, 0x45, 0x54, 0x46, 0x61, 0x61>>) == {:ok, "IETF", <<0x61, 0x61>>}

  end

  test "decode array" do
    assert Cbor.decode(<<0x80>>) == {:ok, [], <<>>}
    assert Cbor.decode(<<0x83, 0x01, 0x02, 0x03>>) == {:ok, [1, 2, 3], <<>>}
    assert Cbor.decode(<<0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05>>) == {:ok, [1, [2, 3], [4, 5]], <<>>}
    assert Cbor.decode(<<0x98,0x19,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x18,0x18,0x19>>) == {:ok, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25], <<>>}
  end

  test "decode map" do
    assert Cbor.decode(<<0xa0>>) == {:ok, %{}, <<>>}
    assert Cbor.decode(<<0xa2, 0x01, 0x02, 0x03, 0x04>>) == {:ok, %{1 => 2, 3 => 4}, <<>>}
    assert Cbor.decode(<<0xa2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x82, 0x02, 0x03>>) == {:ok, %{"a" => 1, "b" => [2, 3]}, <<>>}
    assert Cbor.decode(<<0x82, 0x61, 0x61, 0xa1, 0x61, 0x62, 0x61, 0x63>>) == {:ok, ["a", %{"b" => "c"}], <<>>}
    assert Cbor.decode("\xa5\x61\x61\x61\x41\x61\x62\x61\x42\x61\x63\x61\x43\x61\x64\x61\x44\x61\x65\x61\x45") == {:ok, %{"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E"}, <<>>}
  end
end
