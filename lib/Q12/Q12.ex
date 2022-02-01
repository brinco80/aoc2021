defmodule Q12 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    data_str
    |> String.split("\n", trim: true)
    |> Enum.reduce(
      %{},
      fn line, map ->
        {a, b} =
          line
          |> String.split("-", trim: true)
          |> List.to_tuple()

        case {a, b} do
          {a, "end"} ->
            map
            |> Map.update(a, ["end"], fn val -> List.insert_at(val, 0, "end") end)
            |> Map.put("end", [])

          {"end", b} ->
            map
            |> Map.update(b, ["end"], fn val -> List.insert_at(val, 0, "end") end)
            |> Map.put("end", [])

          _ ->
            map
            |> Map.update(a, [b], fn val -> List.insert_at(val, 0, b) end)
            |> Map.update(b, [a], fn val -> List.insert_at(val, 0, a) end)
        end
      end
    )
    |> Map.new()
  end

  # get path from node x to end
  def path_from(x, graph, path) do
    # add node to path
    path = [x | path]

    # IO.puts("Node #{x}")
    # IO.puts("Path ")
    # path |> IO.inspect()
    # IO.puts("Neighbors of #{x} ")
    # |> IO.inspect()
    ns = get_neighbors(path, graph)

    case ns do
      [] ->
        [path]

      _ ->
        ns
        |> Enum.flat_map(fn n ->
          path_from(n, graph, path)
        end)
    end
  end

  # get neighbors of node x which aren't on path
  def get_neighbors(path, graph) do
    not_allowed =
      path
      |> Enum.filter(fn n -> n == String.downcase(n) end)

    x = hd(path)

    graph[x]
    |> Enum.filter(fn x -> !(x in not_allowed) end)
  end

  # get path from node x to end
  def path_from2(x, graph, path) do
    # add node to path
    path = [x | path]

    # IO.puts("Node #{x}")
    # IO.puts("Path ")
    # path |> IO.inspect()
    # IO.puts("Neighbors of #{x} ")
    # |> IO.inspect()
    ns = get_neighbors2(path, graph)

    case ns do
      [] ->
        [path]

      _ ->
        ns
        |> Enum.flat_map(fn n ->
          path_from2(n, graph, path)
        end)
    end
  end

  @spec more_neighbors(list, map) :: list
  def more_neighbors(path, graph) do
    small_caves_freq =
      path
      |> Enum.filter(fn x -> !(x in ["start", "end"]) && x == String.downcase(x) end)
      |> Enum.frequencies()

    already_visited =
      small_caves_freq
      |> Enum.any?(fn {_k, v} -> v == 2 end)

    if already_visited do
      get_neighbors(path, graph)
    else
      x = hd(path)

      candidates =
        graph[x]
        |> Enum.filter(fn x -> x != "start" end)
        |> MapSet.new()

      extra =
        small_caves_freq
        |> Enum.map(fn {k, _v} -> k end)
        |> MapSet.new()
        |> MapSet.intersection(candidates)

      candidates
      |> MapSet.union(extra)
      |> MapSet.to_list()
    end
  end

  # get neighbors of node x which aren't on path
  @spec get_neighbors2(list, map) :: list
  def get_neighbors2(path, graph) do
    more_neighbors(path, graph)
  end

  def part_i do
    graph = read_and_parse("lib/Q12/data")
    #    print(data)

    paths = path_from("start", graph, [])

    paths
    |> Enum.filter(&(hd(&1) == "end"))
    #   |> IO.inspect()
    |> length()
  end

  def part_ii do
    graph = read_and_parse("lib/Q12/data")
    #    print(data)

    path_from2("start", graph, [])
    |> Enum.filter(&(hd(&1) == "end"))
    #    |> Enum.map(fn path -> Enum.reverse(path) |> Enum.join(",") end)
    #    |> IO.inspect()
    #    |> Enum.sort()
    #    |> Enum.join("\n")
    #    |> IO.puts()
    |> length()
  end
end
