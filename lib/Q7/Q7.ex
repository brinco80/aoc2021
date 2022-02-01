defmodule Q7 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    data_str
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  def fuel(xs, y) do
    xs
    |> Enum.reduce(0, fn xi, f -> f + abs(xi - y) end)
  end

  def fuel2(xs, y) do
    xs
    |> Enum.reduce(
      0,
      fn xi, f ->
        delta = abs(xi - y)
        f + delta * (delta + 1) / 2
      end
    )
  end

  def min_vec(xs) do
    xs |> Enum.reduce(10000, fn x, acc -> min(x, acc) end)
  end

  def max_vec(xs) do
    xs |> Enum.reduce(-10000, fn x, acc -> max(x, acc) end)
  end

  def arg_min_fn(x, {_mm, nil, _i}), do: {x, 0, 1}
  def arg_min_fn(x, {mm, _i_min, i}) when x < mm, do: {x, i, i + 1}
  def arg_min_fn(_x, {mm, i_min, i}), do: {mm, i_min, i + 1}

  def arg_min(xs) do
    xs |> Enum.reduce({10000, nil, 0}, &arg_min_fn/2)
  end

  def part_i do
    xs = read_and_parse("lib/Q7/data")

    x_min = xs |> min_vec
    x_max = xs |> max_vec

    IO.puts("x_min #{x_min} x_max #{x_max}")

    x_min..x_max
    |> Enum.map(fn y -> fuel(xs, y) end)
    |> arg_min
  end

  def part_ii do
    xs = read_and_parse("lib/Q7/data")

    x_min = xs |> min_vec
    x_max = xs |> max_vec

    IO.puts("x_min #{x_min} x_max #{x_max}")

    x_min..x_max
    |> Enum.map(fn y -> fuel2(xs, y) end)
    |> arg_min
  end
end
