defmodule Q24 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n")
    |> Enum.map(fn line ->
      [op | args] =
        line
        |> String.split(" ")

      args =
        args
        |> Enum.map(fn
          arg when arg in ["x", "y", "z", "w"] -> arg
          arg -> String.to_integer(arg)
        end)

      {op, args}
    end)
  end

  def execute(program, digits) do
    state0 = %{"x" => 0, "y" => 0, "z" => 0, "w" => 0}

    program
    |> Enum.reduce(
      {state0, digits},
      fn op, {state, n} -> do_operation(op, n, state) end
    )
  end

  def do_operation({"inp", [var]}, [d | rest], state), do: {%{state | var => d}, rest}

  def do_operation({"add", [x, y]}, n, state) when is_binary(y),
    do: {%{state | x => state[x] + state[y]}, n}

  def do_operation({"add", [x, y]}, n, state), do: {%{state | x => state[x] + y}, n}

  def do_operation({"mul", [x, y]}, n, state) when is_binary(y),
    do: {%{state | x => state[x] * state[y]}, n}

  def do_operation({"mul", [x, y]}, n, state), do: {%{state | x => state[x] * y}, n}

  def do_operation({"div", [x, y]}, n, state) when is_binary(y),
    do: {%{state | x => div(state[x], state[y])}, n}

  def do_operation({"div", [x, y]}, n, state), do: {%{state | x => div(state[x], y)}, n}

  def do_operation({"mod", [x, y]}, n, state) when is_binary(y),
    do: {%{state | x => rem(state[x], state[y])}, n}

  def do_operation({"mod", [x, y]}, n, state), do: {%{state | x => rem(state[x], y)}, n}

  def do_operation({"eql", [x, y]}, n, state) when is_binary(y),
    do: {%{state | x => if(state[x] == state[y], do: 1, else: 0)}, n}

  def do_operation({"eql", [x, y]}, n, state),
    do: {%{state | x => if(state[x] == y, do: 1, else: 0)}, n}

  def simple_program(p) do
    p
    |> Enum.chunk_every(18)
    |> Enum.map(fn p ->
      [
        _inp,
        _mulx0,
        _addxz,
        _modx26,
        {"div", ["z", zd]},
        {"add", ["x", c1]},
        _eqlxw,
        _eqlx0,
        _muly0,
        _addy25,
        _mulyx,
        _addy1,
        _mulzy,
        _muly02,
        _addyw,
        {"add", ["y", c2]},
        _mul_yx,
        _addzy
      ] = p

      fn d, z -> program_step(zd, c1, c2, d, z) end
    end)
  end

  def memoization() do
    fn fun ->
      fn args, acc ->
        acc =
          if(!acc[args]) do
            Map.put(acc, args, fun.(args))
          else
            acc
          end

        {acc, Map.get(acc, args)}
      end
    end
  end

  def program_step(zd, c1, c2, d, z) do
    x = rem(z, 26)
    z = div(z, zd)

    if(x + c1 != d) do
      26 * z + d + c2
    else
      z
    end
  end

  def fast_execute(simple_program, digits) do
    state0 = 0

    simple_program
    |> Enum.reduce(
      {state0, digits},
      fn step, {state, n} ->
        [d | rest] = n
        state = step.(d, state)
        {state, rest}
      end
    )
  end

  def first_digits([d13, d12, d11, d10, d9 | rest]) do
    {26 * 26 * 26 * 26 * (d13 + 5) + 26 * 26 * 26 * (d12 + 5) + 26 * 26 * (d11 + 1) +
       26 * (d10 + 15) + d9 + 2, rest}
  end

  def faster_execute(simple_program, digits) do
    {z, rest} = first_digits(digits)

    simple_program
    |> Enum.reduce(
      {z, rest},
      fn step, {state, n} ->
        [d | rest] = n
        state = step.(d, state)
        {state, rest}
      end
    )
  end

  def part_ia(file \\ "lib/Q24/data") do
    program = read_and_parse(file)
    n = 11_111_111_111_111 * 9

    n..11_111_111_111_111
    |> Stream.map(fn n -> Integer.digits(n) end)
    # filter numbers with 0
    |> Stream.filter(fn ns ->
      ns |> Enum.all?(fn d -> d > 0 end)
    end)
    |> Enum.reduce_while(
      nil,
      fn digits, _ ->
        # IO.puts("Test #{n}")
        case execute(program, digits) do
          %{"z" => z} when z == 0 -> {:halt, n}
          _ -> {:cont, nil}
        end
      end
    )
  end

  def part_ib(file \\ "lib/Q24/data") do
    program = read_and_parse(file)
    n = 11_111_111_111_111 * 9

    sp0 = simple_program(program)

    n..11_111_111_111_111
    |> Stream.map(fn n -> Integer.digits(n) end)
    # filter numbers with 0
    |> Stream.filter(fn ns ->
      ns |> Enum.all?(fn d -> d > 0 end)
    end)
    |> Stream.take(100_000_000)
    |> Enum.reduce_while(
      0,
      fn digits, i ->
        if(rem(i, 10_000_000) == 0, do: IO.puts("Testing #{Integer.undigits(digits)}"))

        case fast_execute(sp0, digits) do
          {0, []} -> {:halt, n}
          {_z, []} -> {:cont, i + 1}
        end
      end
    )
  end

  def part_ic(file \\ "lib/Q24/data") do
    program = read_and_parse(file)
    n = 11_111_111_111_111 * 9

    sp0 = simple_program(program)

    sp = sp0 |> Enum.take(-(length(sp0) - 5))

    # n..11111111111111
    91_111_111_111_111..n
    |> Stream.map(fn n -> Integer.digits(n) end)
    # filter numbers with 0
    |> Stream.filter(fn ns ->
      ns |> Enum.all?(fn d -> d > 0 end)
    end)
    #    |> Stream.take(100_000_000)
    |> Enum.reduce_while(
      0,
      fn digits, i ->
        if(rem(i, 10_000_000) == 0, do: IO.puts("Testing #{Integer.undigits(digits)}"))

        case faster_execute(sp, digits) do
          {0, []} -> {:halt, n}
          {_z, []} -> {:cont, i + 1}
        end
      end
    )
  end

  def part_ii(file \\ "lib/Q14/test") do
  end
end
