defmodule Q13 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    [points, folds] = data_str
    |> String.split("\n\n", trim: true)

    points_tuples = points
    |> String.split("\n")
    |> Enum.map(
      fn line ->
        String.split(line, ",")
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple

    end
    )

    fold_list = folds
    |> String.split("\n", trim: true)
    |> Enum.map(
      fn f ->
        [dir, pos] = Regex.run(~r/fold along ([xy]+)=(\d+)/, f)
        |> tl

        {dir, String.to_integer(pos)}
      end
    )

    max_xy = points_tuples
    |> Enum.reduce({0,0},
      fn {x,y}, {x_max, y_max} ->
        {max(x,x_max), max(y, y_max)}
      end
    )

    {points_tuples, fold_list, max_xy}
  end

  @spec reverse_y(list, integer()) :: list
  def reverse_y(grid, pos) do
    grid |>
    Enum.map(
      fn {x,y} -> {x, -y+2*pos} end
    )
  end

  @spec reverse_x(list, integer()) :: list
  def reverse_x(grid, pos) do
    grid |>
    Enum.map(
      fn {x,y} -> {-x+2*pos, y} end
    )
  end

  def fold_y(grid, pos) do
    top = grid
    |> Enum.filter(fn {_x, y} -> y < pos end )

    bottom = grid
    |> Enum.filter(fn {_x, y} -> y > pos end )
    |> reverse_y(pos)

    top
    |> MapSet.new
    |> MapSet.union( bottom |> MapSet.new)
    |> MapSet.to_list()
  end


  def fold_x(grid, pos) do
    top = grid
    |> Enum.filter(fn {x, _y} -> x < pos end )

    bottom = grid
    |> Enum.filter(fn {x, _y} -> x > pos end )
    |> reverse_x(pos)

    top
    |> MapSet.new
    |> MapSet.union( bottom |> MapSet.new)
    |> MapSet.to_list()
  end

  def fold(grid, {"x", pos}), do: fold_x(grid, pos)
  def fold(grid, {"y", pos}), do: fold_y(grid, pos)

  def print_grid(grid) do
    max_x = Enum.reduce(grid, 0, fn {x,_y}, acc -> max(x,acc) end)
    max_y = Enum.reduce(grid, 0, fn {_x,y}, acc -> max(y,acc) end)

    0..max_x
    |> Enum.map(
      fn x ->
        0..max_y
        |> Enum.map(
          fn y ->
            if {x,y} in grid, do: "#", else: " "
          end
        )
        |> Enum.join("")
      end
    )
    |> Enum.join("\n")
    |> IO.puts()
  end

  def part_i do
    {grid, folds, _max_xy} = read_and_parse("lib/Q13/data")

    fold(grid, hd(folds)) |> length()
  end

  def part_ii do
    {grid, folds, max_xy} = read_and_parse("lib/Q13/data")

    IO.inspect(max_xy)

    final =
    folds
    |> Enum.reduce(grid,
      fn cmd, acc ->
        acc |> fold(cmd)
      end
    )

    final
    |> Enum.map(fn {x,y} -> {y,x} end)
    |> print_grid
  end

end
