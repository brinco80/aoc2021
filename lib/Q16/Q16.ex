defmodule Q16 do

  defstruct version: nil, type: nil, payload: nil

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str |> String.to_integer(16)
  end


  def parse_packet(x) do
    n_bits = Integer.digits(x, 2) |> length()
    n_bits = ceil(n_bits/8)*8

    <<version::size(3), type::size(3), rest::bitstring>> = <<x::size(n_bits)>>

    {payload, rest} = case type do
      4 -> parse_literal(rest, [])
      _ -> {0, rest}
    end

    {%__MODULE__{version: version , type: type, payload: payload}, rest}
  end

  def parse_literal(<<1::1,x::4, rest::bitstring>>, acc), do: parse_literal(rest, [x | acc])
  def parse_literal(<<0::1,x::4, rest::bitstring>>, acc), do: {[x | acc] |> Enum.reverse |> Integer.undigits(16), rest}

  def parse_operator(<<0::1, l::15, rest::bitstring>> ) do
    # keep parsing packets until l bits
    <<valid_payload::size(l), rest::bitstring>> = rest
    parse_packet()
  end

  def parse_operator(<<1::1, p::11, rest::bitstring>> ) do
    {p,rest}

    # keep parsing packets until p packets
  end


  def part_i(file \\ "lib/Q16/test") do
  end

  def part_ii(file \\ "lib/Q16/test") do

  end

end
