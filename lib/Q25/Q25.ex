defmodule Q25 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    sea_floor =
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

    boundaries =
      sea_floor
      |> Map.keys()
      |> Enum.reduce(
        {-1, -1},
        fn {x, y}, {max_x, max_y} ->
          x = max(x, max_x)
          y = max(y, max_y)
          {x, y}
        end
      )

    {sea_floor, boundaries}
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

  def print_state(state) do
    state |> state_to_string |> IO.write()
  end

  def update_state(state0, {mx, my}) do
    horizontal =
      0..mx
      |> Enum.reduce(
        state0,
        fn x, state ->
          0..my
          |> Enum.reduce(
            state,
            fn y, state2 ->
              p = {x, y}

              case state[p] do
                ">" ->
                  y1 = rem(y + 1, my + 1)

                  if(state[{x, y1}] == ".") do
                    state2
                    |> Map.put({x, y}, ".")
                    |> Map.put({x, y1}, ">")
                  else
                    state2
                  end

                _ ->
                  state2
              end
            end
          )
        end
      )

    0..my
    |> Enum.reduce(
      horizontal,
      fn y, state ->
        0..mx
        |> Enum.reduce(
          state,
          fn x, state2 ->
            p = {x, y}

            case state[p] do
              "v" ->
                x1 = rem(x + 1, mx + 1)

                if(state[{x1, y}] == ".") do
                  state2
                  |> Map.put({x, y}, ".")
                  |> Map.put({x1, y}, "v")
                else
                  state2
                end

              _ ->
                state2
            end
          end
        )
      end
    )
  end

  def part_i(file \\ "lib/Q25/test") do
    {state0, boundaries} = read_and_parse(file)

    Stream.iterate(0, &(&1 + 1))
    |> Enum.reduce_while(
      state0,
      fn n, state ->
        new_state = update_state(state, boundaries)

        if state == new_state do
          IO.puts("Stopped at #{n + 1}")
          {:halt, new_state}
        else
          {:cont, new_state}
        end
      end
    )
  end
end
