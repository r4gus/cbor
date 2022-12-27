defmodule CborTest do
  use ExUnit.Case
  doctest Cbor

  test "decode integer smaller 24" do
    assert Cbor.decode(<<0>>) == {:ok, 0}
    assert Cbor.decode(<<1>>) == {:ok, 1}
    assert Cbor.decode(<<0xa>>) == {:ok, 10}
    assert Cbor.decode(<<0x17>>) == {:ok, 23}
  end

  test "decode integer that fits in one byte" do
    assert Cbor.decode(<<0x18, 0x18>>) == {:ok, 24}
    assert Cbor.decode(<<0x18, 0x19>>) == {:ok, 25}
    assert Cbor.decode(<<0x18, 0x64>>) == {:ok, 100}
  end

  test "decode integer that fits in two bytes" do
    assert Cbor.decode(<<0x19, 0x03, 0xe8>>) == {:ok, 1000}
  end

  test "decode integer that fits in four bytes" do
    assert Cbor.decode(<<0x1a, 0x00, 0x0f, 0x42, 0x40>>) == {:ok, 1000000}
  end

  test "decode integer that fits in eight bytes" do
    assert Cbor.decode(<<0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00>>) == {:ok, 1000000000000}
    assert Cbor.decode(<<0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff>>) == {:ok, 18446744073709551615}
  end
end
