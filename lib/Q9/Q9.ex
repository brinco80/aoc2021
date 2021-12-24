defmodule Q9 do

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

    %{x_max: x_max, y_max: y_max, points: points}
  end

  # Corners
  def is_min(0,0, %{points: points}) do
    center = points[{0, 0}]
    right = points[{0, 1}]
    down = points[{1, 0}]

    center < right && center < down
  end

  def is_min(x_max, y_max, %{points: points, x_max: x_max, y_max_: y_max}) do
    center = points[{x_max, y_max}]
    left = points[{x_max-1, y_max}]
    up = points[{x_max, y_max-1}]

    left > center && center < up
  end

  def is_min(0,y_max, %{y_max: y_max, points: points}) do
    center = points[{0, y_max}]
    left = points[{0, y_max-1}]
    down = points[{1, y_max}]

    left > center && center < down
  end


  def is_min(x_max,0, %{x_max: x_max, points: points}) do
    center = points[{x_max, 0}]
    right = points[{x_max, 1}]
    up = points[{x_max-1, 0}]

    center < right && up > center
  end


  # Top line
  def is_min(0,y, %{points: points}) do
    center = points[{0, y}]
    left = points[{0, y-1}]
    right = points[{0, y+1}]
    down = points[{1, y}]

    left > center && center < right && center < down
  end

  # Bottom line
    def is_min(x_max,y, %{points: points, x_max: x_max}) do
      center = points[{x_max, y}]
      left = points[{x_max, y-1}]
      right = points[{x_max, y+1}]
      up = points[{x_max-1, y}]

      left > center && center < right && center < up
    end

  # Left column
  def is_min(x,0, %{points: points}) do
    center = points[{x, 0}]
    right = points[{x, 1}]
    up = points[{x-1, 0}]
    down = points[{x+1, 0}]

    center < right && up > center && center < down
  end

  # Right column
  def is_min(x, y_max, %{y_max: y_max, points: points}) do
    center = points[{x, y_max}]
    left = points[{x, y_max-1}]
    up = points[{x-1, y_max}]
    down = points[{x+1, y_max}]

    center < left && up > center && center < down
  end


  def is_min(x,y, %{points: points}) do
    center = points[{x, y}]
    left = points[{x, y-1}]
    right = points[{x, y+1}]
    up = points[{x-1, y}]
    down = points[{x+1, y}]

    left > center && center < right && up > center && center < down
  end

  def get_value(xys, points) do
    xys |> Enum.map(fn xy -> {xy, points[xy]} end)
  end

  def get_neigh({x,y}, %{x_max: x_max, y_max: y_max, points: points}) do
    case {x,y} do
      {0,0} -> [{0,1}, {1,0}] |> get_value(points)
      {0, ^y_max} -> [{0,y_max-1}, {1,y_max}] |> get_value(points)
      {^x_max,0} -> [{x_max-1,0}, {x_max,1}] |> get_value(points)
      {^x_max, ^y_max} -> [{x_max-1,y_max}, {x_max,y_max-1}] |> get_value(points)
      {0, y} -> [{0, y-1}, {0, y+1}, {1, y}] |> get_value(points)
      {^x_max, y} -> [{x_max, y-1}, {x_max, y+1}, {x_max-1, y}] |> get_value(points)
      {x, 0} -> [{x-1, 0}, {x, 1}, {x+1, 0}] |> get_value(points)
      {x, ^y_max} -> [{x-1, y_max}, {x, y_max-1}, {x+1, y_max}] |> get_value(points)
      {x,y} -> [{x-1, y}, {x, y-1}, {x, y+1}, {x+1, y}] |> get_value(points)
    end
  end

  def get_neighs_recursive({xy, _} = p, max_level, {visited, valid_ns}, points) do
    ns = get_neigh(xy, points)
    |> Enum.filter(fn {xiyi, zi} -> !(xiyi in visited) && zi < max_level end)

    visited = List.insert_at(visited, 0, xy)
    valid_ns = MapSet.put(valid_ns, p)

    case ns do
      [] -> {visited, valid_ns}
      ns ->
        Enum.reduce(ns, {visited, valid_ns},
          fn pi, {v,a} -> get_neighs_recursive(pi, max_level, {v,a}, points) end)

    end
  end

  def get_mins(data) do
    x_max = data[:x_max]
    y_max = data[:y_max]


    0..x_max
    |> Enum.reduce([],
      fn x,acc ->
        line_mins = 0..y_max
        |> Enum.reduce([],
        fn y, acc ->
          if is_min(x,y, data) do
            z = data[:points][{x,y}]
            [{{x,y}, z}| acc]
          else
            acc
          end
        end
        )

      acc ++ line_mins
      end
    )
  end

  def part_i do
    data = read_and_parse("lib/Q9/data")

    data
    |> get_mins
    |> Enum.map(fn {{_x,_y}, z} -> z+1 end)
    |> Enum.sum
  end



  def part_ii do
    points = read_and_parse("lib/Q9/data")

    get_mins(points)
    |> Enum.map(
      fn {{xi,yi},zi} ->
        get_neighs_recursive({{xi,yi}, zi}, 9, {[], MapSet.new()}, points)
      end
    )
    |> Enum.map(fn {_, basin} -> MapSet.size(basin) end  )
    |> Enum.sort( :desc)
    |> Enum.take(3)
    |> Enum.product()
  end
end
