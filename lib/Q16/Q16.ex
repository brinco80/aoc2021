defmodule Q16 do
  defstruct version: nil, type: nil, payload: nil

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str |> String.to_integer(16)
  end

  def parse_packet(x) when is_bitstring(x) do
    # parse header
    <<version::size(3), type::size(3), rest::bitstring>> = x
    # IO.inspect(rest)
    {payload, rest} =
      case type do
        4 -> parse_literal(rest, [])
        _ -> parse_operator(rest)
      end

    {%__MODULE__{version: version, type: type, payload: payload}, rest}
  end

  def parse_packet(x) when is_integer(x) do
    n_bits = Integer.digits(x, 2) |> length()
    n_bits = ceil(n_bits / 8) * 8

    parse_packet(<<x::size(n_bits)>>)
  end

  def parse_literal(<<1::1, x::4, rest::bitstring>>, acc), do: parse_literal(rest, [x | acc])

  def parse_literal(<<0::1, x::4, rest::bitstring>>, acc),
    do: {[x | acc] |> Enum.reverse() |> Integer.undigits(16), rest}

  def is_zero(""), do: true
  def is_zero(<<0::1>>), do: true
  def is_zero(<<1::1, _rest::bitstring>>), do: false
  def is_zero(<<0::1, rest::bitstring>>), do: is_zero(rest)

  def parse_operator(<<0::1, l::15, rest::bitstring>>) do
    # extract l bits
    <<valid_data::size(l), rest::bitstring>> = rest

    payloads =
      Stream.cycle([0])
      |> Enum.reduce_while(
        {[], <<valid_data::size(l)>>},
        fn _i, {payloads, r} ->
          case is_zero(r) do
            true ->
              {:halt, payloads}

            false ->
              {packet, new_rest} = parse_packet(r)
              {:cont, {[packet | payloads], new_rest}}
          end
        end
      )

    {payloads, rest}
  end

  def parse_operator(<<1::1, p::11, rest::bitstring>>) do
    # Parse p packets
    0..(p - 1)
    |> Enum.reduce(
      {[], rest},
      fn _i, {payloads, r} ->
        {packet, new_rest} = parse_packet(r)
        {[packet | payloads], new_rest}
      end
    )
  end

  def add_packet_version(%__MODULE__{version: v, payload: p} = _packet, acc) do
    new_acc = acc + v

    case p do
      x when is_integer(x) ->
        new_acc

      _ ->
        Enum.reduce(p, new_acc, fn payload, acc ->
          add_packet_version(payload, acc)
        end)
    end
  end

  def boolean_to_int(false), do: 0
  def boolean_to_int(true), do: 1

  # literal
  def eval_packet(%__MODULE__{version: _v, payload: p, type: 4} = _packet), do: p

  # greater than
  def eval_packet(%__MODULE__{version: _v, payload: [b, a], type: 5} = _packet) do
    (eval_packet(a) > eval_packet(b)) |> boolean_to_int()
  end

  # less than
  def eval_packet(%__MODULE__{version: _v, payload: [b, a], type: 6} = _packet) do
    (eval_packet(a) < eval_packet(b)) |> boolean_to_int()
  end

  # equal
  def eval_packet(%__MODULE__{version: _v, payload: [b, a], type: 7} = _packet) do
    (eval_packet(a) == eval_packet(b)) |> boolean_to_int()
  end

  # sum
  def eval_packet(%__MODULE__{version: _v, payload: ps, type: 0} = _packet) do
    ps
    |> Enum.reduce(
      0,
      fn p, acc ->
        acc + eval_packet(p)
      end
    )
  end

  # prod
  def eval_packet(%__MODULE__{version: _v, payload: ps, type: 1} = _packet) do
    ps
    |> Enum.reduce(
      1,
      fn p, acc ->
        acc * eval_packet(p)
      end
    )
  end

  # min
  def eval_packet(%__MODULE__{version: _v, payload: ps, type: 2} = _packet) do
    ps
    |> Enum.reduce(
      :infinity,
      fn p, acc ->
        min(acc, eval_packet(p))
      end
    )
  end

  # max
  def eval_packet(%__MODULE__{version: _v, payload: ps, type: 3} = _packet) do
    ps
    |> Enum.reduce(
      -1,
      fn p, acc ->
        max(acc, eval_packet(p))
      end
    )
  end

  def part_i(file \\ "lib/Q16/data") do
    message = read_and_parse(file)
    {packet, _rest} = parse_packet(message) |> IO.inspect()

    add_packet_version(packet, 0)
  end

  def part_ii(file \\ "lib/Q16/test") do
    message = read_and_parse(file) |> IO.inspect()
    {packet, _rest} = parse_packet(message) |> IO.inspect()

    {packet, eval_packet(packet)}
  end

  def part_ii_text(text) do
    message =
      text
      |> IO.inspect()
      |> String.to_integer(16)

    {packet, _rest} = parse_packet(message) |> IO.inspect()

    {packet, eval_packet(packet)}
  end
end
