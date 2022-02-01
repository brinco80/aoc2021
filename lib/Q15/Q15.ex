defmodule Q15 do
  @spec read_and_parse(binary) :: %{points: map, x_max: any, y_max: any}
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    points =
      data_str
      |> String.split("\n")
      |> Enum.with_index(fn element, index -> {index, element} end)
      |> Enum.flat_map(fn {x, line} ->
        line
        |> String.split("", trim: true)
        |> Enum.with_index(fn element, index -> {index, String.to_integer(element)} end)
        |> Enum.map(fn {y, z} ->
          {{x, y}, z}
        end)
      end)
      |> Map.new()

    {x_max, y_max} =
      points
      |> Map.keys()
      |> Enum.reduce({-1, -1}, fn {x, y}, {x_max, y_max} -> {max(x_max, x), max(y_max, y)} end)

    %{x_max: x_max, y_max: y_max, points: points}
  end

  @spec get_value(list, map) :: list
  def get_value(xys, points) do
    xys |> Enum.map(fn xy -> {xy, points[xy]} end)
  end

  @spec get_neighbors_diag({number, number}, %{
          :points => map,
          :x_max => any,
          :y_max => any,
          optional(any) => any
        }) :: list
  def get_neighbors_diag({x, y}, %{x_max: x_max, y_max: y_max, points: points}) do
    case {x, y} do
      {0, 0} ->
        [{0, 1}, {1, 1}, {1, 0}] |> get_value(points)

      {0, ^y_max} ->
        [{0, y_max - 1}, {1, y_max - 1}, {1, y_max}] |> get_value(points)

      {^x_max, 0} ->
        [{x_max - 1, 0}, {x_max - 1, 1}, {x_max, 1}] |> get_value(points)

      {^x_max, ^y_max} ->
        [{x_max - 1, y_max}, {x_max - 1, y_max - 1}, {x_max, y_max - 1}] |> get_value(points)

      {0, y} ->
        [{0, y - 1}, {0, y + 1}, {1, y}, {1, y - 1}, {1, y + 1}] |> get_value(points)

      {^x_max, y} ->
        [{x_max, y - 1}, {x_max, y + 1}, {x_max - 1, y}, {x_max - 1, y - 1}, {x_max - 1, y + 1}]
        |> get_value(points)

      {x, 0} ->
        [{x - 1, 0}, {x, 1}, {x + 1, 0}, {x - 1, 1}, {x + 1, 1}] |> get_value(points)

      {x, ^y_max} ->
        [{x - 1, y_max}, {x, y_max - 1}, {x + 1, y_max}, {x - 1, y_max - 1}, {x + 1, y_max - 1}]
        |> get_value(points)

      {x, y} ->
        [
          {x - 1, y - 1},
          {x - 1, y},
          {x - 1, y + 1},
          {x, y - 1},
          {x, y + 1},
          {x + 1, y - 1},
          {x + 1, y},
          {x + 1, y + 1}
        ]
        |> get_value(points)
    end
  end

  @spec get_neighbors({number, number}, %{
          :points => map,
          :x_max => any,
          :y_max => any,
          optional(any) => any
        }) :: list
  def get_neighbors({x, y}, %{x_max: x_max, y_max: y_max, points: points}) do
    case {x, y} do
      # corners
      {0, 0} -> [{0, 1}, {1, 0}] |> get_value(points)
      {0, ^y_max} -> [{0, y_max - 1}, {1, y_max}] |> get_value(points)
      {^x_max, 0} -> [{x_max - 1, 0}, {x_max, 1}] |> get_value(points)
      {^x_max, ^y_max} -> [{x_max - 1, y_max}, {x_max, y_max - 1}] |> get_value(points)
      # borders
      {0, y} -> [{0, y - 1}, {0, y + 1}, {1, y}] |> get_value(points)
      {^x_max, y} -> [{x_max, y - 1}, {x_max, y + 1}, {x_max - 1, y}] |> get_value(points)
      {x, 0} -> [{x - 1, 0}, {x, 1}, {x + 1, 0}] |> get_value(points)
      {x, ^y_max} -> [{x - 1, y_max}, {x, y_max - 1}, {x + 1, y_max}] |> get_value(points)
      # interior
      {x, y} -> [{x - 1, y}, {x, y - 1}, {x, y + 1}, {x + 1, y}] |> get_value(points)
    end
  end

  def manhattan_distance({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  def build_path(came_from, end_node) do
    path = [end_node]

    Stream.cycle([0])
    |> Enum.reduce_while(
      path,
      fn _i, [current | _] = path ->
        case came_from[current] do
          nil -> {:halt, path}
          n -> {:cont, [n | path]}
        end
      end
    )
  end

  def astar_search(start, goal, environment, h) do
    # set of opened points
    open_set = Prioqueue.new([{0, start}])
    # where a node came from
    came_from = %{}

    # effective cost from start to node n
    gScore = %{start => 0}
    # estimated cost from start to node n: gScore + fScore at node n
    fScore = %{start => h.(start)}

    came_from =
      Stream.cycle([1])
      |> Enum.reduce_while(
        %{open_set: open_set, gScore: gScore, fScore: fScore, came_from: came_from},
        fn _, %{open_set: open_set, gScore: gScore, fScore: fScore, came_from: came_from} ->
          case Prioqueue.extract_min(open_set) do
            # error
            {:error, :empty} ->
              {:halt, []}

            # i reach goal! end loop and return path
            {:ok, {{_, ^goal}, _}} ->
              {:halt, came_from}

            {:ok, {{_, current_node}, open_set}} ->
              new_acc =
                get_neighbors(current_node, environment)
                |> Enum.reduce(
                  %{open_set: open_set, gScore: gScore, fScore: fScore, came_from: came_from},
                  fn {n, z},
                     %{open_set: open_set, gScore: gScore, fScore: fScore, came_from: came_from} =
                       acc ->
                    tentative_gScore = gScore[current_node] + z

                    if tentative_gScore < gScore[n] do
                      came_from = Map.put(came_from, n, current_node)
                      gScore = Map.put(gScore, n, tentative_gScore)
                      # |> IO.inspect()
                      fScore = Map.put(fScore, n, tentative_gScore + h.(n))

                      open_set =
                        if !Prioqueue.member?(open_set, n) do
                          Prioqueue.insert(open_set, {tentative_gScore + h.(n), n})
                        else
                          open_set
                        end

                      %{open_set: open_set, gScore: gScore, fScore: fScore, came_from: came_from}
                    else
                      acc
                    end
                  end
                )

              {:cont, new_acc}
          end
        end
      )

    build_path(came_from, goal)
  end

  def expand_map(%{x_max: x_max, y_max: y_max, points: points}, factor) do
    factors =
      0..(factor - 1)
      |> Enum.flat_map(fn f ->
        0..(factor - 1)
        |> Enum.map(fn g -> {f, g} end)
      end)

    new_points =
      factors
      |> Enum.flat_map(fn {f, g} ->
        points
        |> Enum.reduce(
          [],
          fn {{x, y}, z}, acc ->
            [
              {{f * (x_max + 1) + x, g * (y_max + 1) + y}, Integer.mod(z + f + g - 1, 9) + 1}
              | acc
            ]
          end
        )
      end)
      |> Map.new()

    %{x_max: factor * (x_max + 1) - 1, y_max: factor * (y_max + 1) - 1, points: new_points}
  end

  def print_map(%{x_max: x_max, y_max: y_max, points: points}) do
    0..x_max
    |> Enum.reduce(
      [],
      fn x, acc ->
        new_line =
          0..y_max
          |> Enum.map(fn y ->
            points[{x, y}]
          end)
          |> Enum.join()

        [new_line | acc]
      end
    )
    |> Enum.reverse()
    |> Enum.join("\n")
  end

  def part_i(file \\ "lib/Q15/test") do
    env = read_and_parse(file)

    %{x_max: x_max, y_max: y_max} = env

    start_point = {0, 0}
    goal = {x_max, y_max}

    h = fn p -> manhattan_distance(p, goal) end

    astar_search(start_point, goal, env, h)
    # remove start point
    |> tl
    |> IO.inspect()
    |> get_value(env[:points])
    |> Enum.map(fn {_p, c} -> c end)
    |> Enum.sum()
  end

  def part_ii(file \\ "lib/Q15/test") do
    env =
      read_and_parse(file)
      |> expand_map(5)

    %{x_max: x_max, y_max: y_max} = env

    start_point = {0, 0}
    goal = {x_max, y_max}

    h = fn p -> manhattan_distance(p, goal) end

    astar_search(start_point, goal, env, h)
    # remove start point
    |> tl
    |> IO.inspect()
    |> get_value(env[:points])
    |> Enum.map(fn {_p, c} -> c end)
    |> Enum.sum()
  end
end
