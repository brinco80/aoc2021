defmodule Q11 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    points = data_str
    |> String.split("\n")
    |> Enum.with_index(fn element, index -> {index, element} end)
    |> Enum.flat_map(
        fn {x, line} ->
          line
          |> String.split("", trim: true)
          |> Enum.with_index(fn element, index -> {index, String.to_integer(element)} end)
          |> Enum.map(
            fn {y,z} ->
              {{x,y}, z}
            end
          )
        end
      )
    |> Map.new

    {x_max, y_max} = points
    |> Map.keys
    |> Enum.reduce({-1, -1}, fn {x,y}, {x_max, y_max} -> {max(x_max, x), max(y_max, y)} end)

    %{x_max: x_max, y_max: y_max, points: points, flashes: MapSet.new}
  end

  def get_value(xys, points) do
    xys |> Enum.map(fn xy -> {xy, points[xy]} end)
  end

  def get_neigh({x,y}, %{x_max: x_max, y_max: y_max, points: points}) do
    case {x,y} do
      {0,0} -> [{0,1}, {1,1}, {1,0}] |> get_value(points)
      {0, ^y_max} -> [{0,y_max-1}, {1,y_max-1}, {1,y_max}] |> get_value(points)
      {^x_max,0} -> [{x_max-1,0}, {x_max-1, 1}, {x_max,1}] |> get_value(points)
      {^x_max, ^y_max} -> [{x_max-1,y_max}, {x_max-1, y_max-1}, {x_max,y_max-1}] |> get_value(points)
      {0, y} -> [{0, y-1}, {0, y+1}, {1, y}, {1, y-1}, {1, y+1}] |> get_value(points)
      {^x_max, y} -> [{x_max, y-1}, {x_max, y+1}, {x_max-1, y}, {x_max-1, y-1}, {x_max-1, y+1}] |> get_value(points)
      {x, 0} -> [{x-1, 0}, {x, 1}, {x+1, 0}, {x-1, 1}, {x+1, 1} ] |> get_value(points)
      {x, ^y_max} -> [{x-1, y_max}, {x, y_max-1}, {x+1, y_max}, {x-1, y_max-1}, {x+1, y_max-1} ] |> get_value(points)
      {x,y} -> [{x-1, y-1}, {x-1, y}, {x-1, y+1}, {x, y-1}, {x, y+1}, {x+1, y-1}, {x+1, y}, {x+1, y+1}] |> get_value(points)
    end
  end

  def update_state(%{points: points, x_max: x_max, y_max: y_max}= state) do
    # Add one to all points
    plus1 = points
    |> Enum.map(fn {p,v} -> {p,v+1} end)


    # Need to keep track of flashing octopusses
    flashed = MapSet.new()

    {flashed, points} = Stream.cycle([0])
    |> Enum.reduce_while({flashed, plus1},
      fn _, {flashed, acc} ->
        to_flash = acc
        |> Enum.filter( fn {_k,v} -> v>9 end )

        # get only non flashed ones
        points_to_flash = to_flash |> Enum.map( fn {k,_v} -> k  end) |> MapSet.new
        valid_points = MapSet.difference(points_to_flash, flashed) |> MapSet.to_list()
        to_flash = to_flash |> Enum.filter(fn {k,_v} -> k in valid_points end)

        # update flashed acc
        flashed = MapSet.union(flashed, MapSet.new(valid_points))

        if length(to_flash) > 0 do
          # Add 1 to all neighbors
          new_acc = to_flash
          |> Enum.reduce(Map.new(acc),
            fn {p,_z}, acc ->
              get_neigh(p, %{points: Map.new(acc), x_max: x_max, y_max: y_max})
              |> Enum.reduce(acc,
                fn {pp, _zz}, acc2 ->
                  Map.update!(acc2, pp, &(&1 + 1) )
                end
              )
            end
          )
          {:cont, {flashed, new_acc}}
        else
          {:halt, {flashed, acc}}
        end
      end
    )

    # Set flashed ones to 0
    points = points
    |> Enum.map(
      fn {p,v} ->
        case v do
          v when v>9 -> {p,0}
          _ -> {p,v}
        end
      end
    )
    |> Map.new


    n_flashes = MapSet.size(flashed)

    Map.put(%{state | points: points}, :n_flashes, n_flashes)
  end

  def print(%{points: p, x_max: x_max, y_max: y_max} = _state) do
    0..x_max
    |> Enum.map(
      fn x ->
        0..y_max
        |> Enum.map(fn y -> p[{x,y}] end)
        |> Enum.join("")
      end
    ) |> Enum.join("\n") |> IO.puts
    IO.puts("\n")

  end

  def part_i(n) do
    data = read_and_parse("lib/Q11/data")
    print(data)

    1..n |>
    Enum.reduce({0, data}, fn _i, {n, state} ->
      state = update_state(state)
      state |> print
      n = n + state[:n_flashes]
      {n, state}
     end)

  end



  def part_ii(n_it) do
    data = read_and_parse("lib/Q11/data")
    print(data)

    1..n_it |>
    Enum.reduce_while({0, data}, fn i, {n, state} ->
      state = update_state(state)
      state |> print
      n = n + state[:n_flashes]
      if state[:n_flashes] == 100 do
        IO.puts("All sync @ #{i}")
        {:halt, {n, state}}
      else
        {:cont, {n, state}}
      end

     end)
  end
end
