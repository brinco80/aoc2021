defmodule Q23 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n")
    |> Enum.with_index(fn element, i -> {i, element} end)
    |> Enum.flat_map(fn {i, line} ->
      line
      |> String.split("", trim: true)
      |> Enum.with_index(fn element, j -> {j, element} end)
      |> Enum.map(fn {j, z} ->
        {{i, j}, z}
      end)
    end)
    |> Map.new()
    # Remove empty spaces
    |> Map.filter(fn {_k, v} -> v != "" end)
  end

  def state_to_string(state) do
    keys =
      state
      |> Map.keys()

    {max_i, max_j} =
      for {i, j} <- keys, reduce: {-1, -1} do
        {m, n} -> {max(m, i), max(n, j)}
      end

    for i <- 0..max_i, j <- 0..(max_j + 1) do
      if(j == max_j + 1, do: "\n", else: Map.get(state, {i, j}, " "))
    end
    |> Enum.join()
  end

  def transition_to_string(from, to) do
    keys =
      from
      |> Map.keys()

    {max_i, max_j} =
      for {i, j} <- keys, reduce: {-1, -1} do
        {m, n} -> {max(m, i), max(n, j)}
      end

    for i <- 0..max_i, j <- 0..(2 * max_j + 3) do
      case j do
        x when x <= max_j -> Map.get(from, {i, x}, " ")
        x when x == max_j + 1 -> "    "
        x when x <= 2 * max_j + 2 -> Map.get(to, {i, x - (max_j + 2)}, " ")
        _ -> "\n"
      end
    end
    |> Enum.join()
  end

  def print_state(state) do
    state |> state_to_string |> IO.write()
  end

  def free_amphipods(state) do
    state
    |> Map.filter(fn {pos, amp} ->
      if amp not in ["A", "B", "C", "D"] do
        false
      else
        ns =
          pos
          |> get_neighbors()
          |> get_value(state)
          |> Enum.filter(fn {_k, v} -> v == "." end)

        ns != []
      end
    end)
  end

  def hall_available(k, state) do
    [(k - 1)..1, (k + 1)..11]
    |> Enum.map(fn l ->
      l
      |> Enum.reduce_while(
        [],
        fn j, acc ->
          case j do
            x when x in [3, 5, 7, 9] ->
              {:cont, acc}

            _ ->
              if state[{1, j}] == "." do
                {:cont, [{1, j} | acc]}
              else
                {:halt, acc}
              end
          end
        end
      )
    end)
    |> Enum.concat()
  end

  def room_columns() do
    %{
      "A" => 3,
      "B" => 5,
      "C" => 7,
      "D" => 9
    }
  end

  def path_to_room_open({{1, m}, amp}, state) do
    rooms = room_columns()

    n = if(m < rooms[amp], do: m + 1, else: m - 1)

    n..rooms[amp]
    |> Enum.reduce_while(
      nil,
      fn j, _acc ->
        case state[{1, j}] do
          "." -> {:cont, true}
          _ -> {:halt, nil}
        end
      end
    )
  end

  def room_state(a, state) do
    rooms = room_columns()

    j = rooms[a]

    2..6
    |> Enum.reduce_while(
      :empty,
      fn i, _acc ->
        case state[{i, j}] do
          x when x in ["A", "B", "C", "D"] ->
            if i == 2 do
              {:halt, :full}
            else
              {:halt, {i - 1, j}}
            end

          "#" ->
            {:halt, {i - 1, j}}

          _ ->
            {:cont, nil}
        end
      end
    )
  end

  def is_room_ready(a, state) do
    rooms = room_columns()

    j = rooms[a]

    2..6
    |> Enum.reduce_while(
      true,
      fn i, acc ->
        case state[{i, j}] do
          ^a -> {:cont, true}
          "." -> {:cont, true}
          "#" -> {:halt, acc}
          _ -> {:halt, false}
        end
      end
    )
  end

  def new_states(moves, state) do
    moves
    |> Enum.flat_map(fn {from, {amp, tos}} ->
      new_state =
        state
        |> Map.put(from, ".")

      tos
      |> Enum.map(fn to ->
        {
          new_state
          |> Map.put(to, amp),
          costs(amp) * manhattan_distance(from, to)
        }
      end)
    end)
  end

  def costs(amp) do
    %{
      "A" => 1,
      "B" => 10,
      "C" => 100,
      "D" => 1000
    }
    |> Map.get(amp)
  end

  # Counts amphipods in a bad position (Debería agregar que primero vea que la habitación es válida)
  def bad_amphs(state, i_max) do
    rooms = room_columns()

    # Rooms ready to host hall amphipods
    ready_rooms =
      for amp <- Map.keys(rooms), into: %{} do
        {amp, is_room_ready(amp, state)}
      end

    good_amphs_score =
      ready_rooms
      |> Map.filter(fn {_, v} -> v end)
      |> Map.map(fn {amp, _} -> Map.get(rooms, amp) end)
      |> Map.map(fn {amp, j} ->
        2..i_max
        |> Enum.reduce(
          0,
          fn i, acc ->
            acc + if(state[{i, j}] == amp, do: 1, else: 0)
          end
        )
      end)
      |> Enum.reduce(
        0,
        fn {amp, n}, acc ->
          costs(amp) * n + acc
        end
      )

    4 * (1 + 10 + 100 + 1000) - good_amphs_score
  end

  def get_moves(state) do
    rooms = room_columns()
    rooms_positions = Map.values(rooms)

    # Amphipods free to move
    free_amp = free_amphipods(state)

    rooms_states =
      for amp <- Map.keys(rooms), into: %{} do
        {amp, room_state(amp, state)}
      end

    # Rooms ready to host hall amphipods
    ready_rooms =
      for amp <- Map.keys(rooms), into: %{} do
        {amp, is_room_ready(amp, state)}
      end

    # Amphipods that still don't leave their rooms
    room_amphipods =
      free_amp
      |> Map.filter(fn {{_i, j}, amp} ->
        j in rooms_positions and not (ready_rooms[amp] and rooms[amp] == j)
      end)

    # Room amphipods next moves
    room_amp_next_moves =
      room_amphipods
      |> Map.map(fn {{_x, y}, z} -> {z, hall_available(y, state)} end)
      |> Map.filter(fn {_k, {_a, l}} -> l != [] end)

    # Amphipods already at the hall
    hall_amphipods =
      free_amp
      |> Map.filter(fn {{i, _j}, _v} -> i == 1 end)

    # Hall amphipods next moves
    ha_nm =
      hall_amphipods
      |> Map.map(fn {{i, j}, amp} ->
        if ready_rooms[amp] and path_to_room_open({{i, j}, amp}, state) do
          {amp, [rooms_states[amp]]}
        else
          nil
        end
      end)
      |> Map.filter(fn {_k, v} -> v end)

    # Generate new states from feasible moves
    moves = Map.merge(room_amp_next_moves, ha_nm)

    moves |> new_states(state)
  end

  @spec get_value(list, map) :: list
  def get_value(xys, points) do
    xys |> Enum.map(fn xy -> {xy, points[xy]} end)
  end

  def get_neighbors({x, y}) do
    [{x - 1, y}, {x, y - 1}, {x, y + 1}, {x + 1, y}]
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

  def cmp_fun({_c_a, a}, {_c_b, b}) when a === b, do: :eq
  def cmp_fun({c_a, _a}, {c_b, _b}) when c_a < c_b, do: :lt
  def cmp_fun({c_a, _a}, {c_b, _b}) when c_a >= c_b, do: :gt

  def astar_search(start, goal, h) do
    # set of opened points
    open_set0 = Prioqueue.new([{0, start}], cmp_fun: &__MODULE__.cmp_fun/2)
    # where a node came from
    came_from0 = %{}

    # effective cost from start to node n
    gScore0 = %{start => 0}

    {came_from, gScore} =
      Stream.cycle([1])
      |> Enum.reduce_while(
        %{open_set: open_set0, gScore: gScore0, came_from: came_from0},
        fn _, %{open_set: open_set, gScore: gScore, came_from: came_from} ->
          case Prioqueue.extract_min(open_set) do
            {:error, :empty} ->
              IO.puts("Queue is empty!!!")
              # error
              {:halt, {came_from, gScore}}

            {:ok, {{_, ^goal}, _}} ->
              # goal reached! end loop, return path and costs
              {:halt, {came_from, gScore}}

            {:ok, {{_est_cost, current_node}, open_set}} ->
              new_acc =
                get_moves(current_node)
                |> Enum.reduce(
                  %{open_set: open_set, gScore: gScore, came_from: came_from},
                  fn {n, cost},
                     %{open_set: open_set, gScore: gScore, came_from: came_from} = acc ->
                    tentative_gScore = gScore[current_node] + cost

                    if tentative_gScore < gScore[n] do
                      came_from = Map.put(came_from, n, current_node)
                      gScore = Map.put(gScore, n, tentative_gScore)

                      open_set =
                        if !Prioqueue.member?(open_set, {nil, n}) do
                          Prioqueue.insert(open_set, {tentative_gScore + h.(n), n})
                        else
                          open_set
                        end

                      %{open_set: open_set, gScore: gScore, came_from: came_from}
                    else
                      acc
                    end
                  end
                )

              {:cont, new_acc}
          end
        end
      )

    {build_path(came_from, goal), gScore}
  end

  def part_i(file \\ "lib/Q23/test") do
    start_point = read_and_parse(file)

    goal = read_and_parse("lib/Q23/goal1")

    h = fn state -> bad_amphs(state, 3) end
    # h = fn state -> 0 end

    {path, costs} = astar_search(start_point, goal, h)
    Enum.map(path, &print_state/1)
    IO.puts("# Nodes open #{map_size(costs)}")
    IO.puts("Cost is #{costs[goal]}")
  end

  def part_ii(file \\ "lib/Q15/data2") do
    start_point = read_and_parse(file)

    goal = read_and_parse("lib/Q23/goal2")

    h = fn state -> bad_amphs(state, 5) end

    # h = fn _state -> 0 end

    {path, costs} = astar_search(start_point, goal, h)
    IO.puts(path |> length())

    Enum.map(path, fn state ->
      print_state(state)
      IO.puts("\n")
    end)

    IO.puts("# Nodes open #{map_size(costs)}")
    IO.puts("Cost is #{costs[goal]}")
  end
end
