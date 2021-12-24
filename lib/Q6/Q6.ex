defmodule Q6 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    data_str |> String.split(",") |>
      Enum.map(&String.to_integer/1)
  end

  def init_state(seeds) do
    state = Enum.map(0..8, fn _x -> 0 end)
    seeds
    |> Enum.reduce(state, fn n, state -> List.update_at(state, n, &(&1 + 1)) end)
  end

  def update_state( [h | t] ) do
    t ++ [h]
    |> List.update_at(6, &(&1 + h))
    # |> Enum.flat_map(
    # fn %__MODULE__{t: t} = s ->
    #   if t>0 do
    #     [%{s | t: t-1}]
    #   else
    #     [%{s | t: 8}, %{s | t: 6}]
    #   end
    # end)
  end

  def part_i(n) do
    fishes = read_and_parse("lib/Q6/data")
    state = init_state(fishes) |> IO.inspect()
    1..n |> Enum.reduce(state, fn _n, acc -> update_state(acc) |> IO.inspect() end) |> Enum.sum()

  end


end
