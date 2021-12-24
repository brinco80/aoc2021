defmodule Q5 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to lines
    lines = data_str |> String.split("\n") |>
      Enum.filter( fn x -> x != "" end)


    lines
    |> Enum.map(fn line ->
      String.split(line, " -> ")
      |> Enum.map(
        fn x ->
          String.split(x,",")
          |> Enum.map(&String.to_integer/1)
          |> List.to_tuple
        end)
        |> List.to_tuple
    end)

  end

  def filter_lines({{x1,y1}, {x2,y2}}), do: x1 == x2 || y1 == y2

  def filter_hor_ver(points) do
    points
    |> Enum.filter(&filter_lines/1)
  end


  def get_lines(points) do
    points
    |> Enum.map(
      fn p ->
        case p do
          {{x,y1}, {x,y2}} -> # vertical line
            y1..y2 |> Enum.map(fn y -> {x,y} end)
          {{x1,y}, {x2,y}} -> # horizontal line
            x1..x2 |> Enum.map(fn x -> {x,y} end)
          {{x1,y1}, {x2,y2}} when ((x1 < x2) and (y1 < y2)) -> # positive, positive slope
            0..(x2-x1) |> Enum.reduce([], fn n,acc -> [{x1+n,y1+n} | acc] end)
          {{x1,y1}, {x2,y2}} when ((x1 < x2) and (y1 > y2)) -> # positive, negative slope
            0..(x2-x1) |> Enum.reduce([], fn n,acc -> [{x1+n,y1-n} | acc] end)
          {{x1,y1}, {x2,y2}} when ((x1 > x2) and (y1 < y2)) -> # negative, postivie slope
            0..(x1-x2) |> Enum.reduce([], fn n,acc ->  [{x1-n,y1+n} | acc] end)
          {{x1,y1}, {x2,y2}} when ((x1 > x2) and (y1 > y2)) -> # negative, negative slope
            0..(x1-x2) |> Enum.reduce([], fn n,acc -> [{x1-n,y1-n} | acc] end)
        end
      end)
  end

  def part_i do
    points = read_and_parse("lib/Q5/data")
    |> filter_hor_ver

    points_freq = get_lines(points)
    |> Enum.reduce(%{},
      fn line, acc ->
        Enum.reduce(line, acc,
        fn point, acc ->
          Map.update(acc, point, 1, fn v -> v+1 end)
        end
        )
      end
    )

    n_dangerous_points = points_freq
    |> Enum.filter(
      fn {_k,v} ->
        v>1
      end
    )
    |> length

    IO.puts("There are #{n_dangerous_points} dangerous points")
  end


  def part_ii do
    points = read_and_parse("lib/Q5/data")

    points_freq = get_lines(points)
    |> Enum.reduce(%{},
      fn line, acc ->
        Enum.reduce(line, acc,
        fn point, acc ->
          Map.update(acc, point, 1, fn v -> v+1 end)
        end
        )
      end
    )

    n_dangerous_points = points_freq
    |> Enum.filter(
      fn {_k,v} ->
        v>1
      end
    )
    |> length

    IO.puts("There are #{n_dangerous_points} dangerous points")
  end

end
