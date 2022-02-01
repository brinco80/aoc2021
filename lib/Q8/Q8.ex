defmodule Q8 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    data_str
    |> String.split("\n")
    |> Enum.map(fn line ->
      [data, output] = String.split(line, " | ")
      data = String.split(data, " ")
      output = String.split(output, " ")
      {data, output}
    end)
  end

  def ss_dict do
    %{
      "0": ["a", "b", "c", "e", "f", "g"],
      "1": ["c", "f"],
      "2": ["a", "c", "d", "e", "g"],
      "3": ["a", "c", "d", "f", "g"],
      "4": ["b", "c", "d", "f"],
      "5": ["a", "b", "d", "f", "g"],
      "6": ["a", "b", "d", "e", "f", "g"],
      "7": ["a", "c", "f"],
      "8": ["a", "b", "c", "d", "e", "f", "g"],
      "9": ["a", "b", "c", "d", "f", "g"]
    }
  end

  def n_dict do
    %{
      "2": 1,
      "3": 7,
      "4": 4,
      "7": 8
    }
  end

  def train(input) do
    # easy numbers 1, 4, 7 and 8
    # useful equations
    # 1 ^ 7 = a (top segment)
    # 4 \ 1 = bd
    # 1 ^ 3 = 1 (to identify 3 among 2,3 and 5)
    # bd ^ 5 = bd (to identify 5 among 2 and 5)
    # 4 ^ 9 = 4 (to identify 9 among 6, 9 and 0)
    # 0 ^ 1 = 1 (to identify 0 among 6, 9 and 0)
    # 1 ^ 9 = 1 (to identify 9 between 6 and 9)

    # Compute length and assign buckets for each size
    ns =
      input
      |> Enum.reduce(
        %{},
        fn x, acc ->
          n = String.length(x)
          x_set = x |> String.split("", trim: true) |> MapSet.new()
          key = to_string(n) |> String.to_atom()
          Map.update(acc, key, [x_set], fn val -> List.insert_at(val, 0, x_set) end)
        end
      )

    one = hd(ns[:"2"])
    seven = hd(ns[:"3"])
    four = hd(ns[:"4"])
    eight = hd(ns[:"7"])

    bd = MapSet.difference(four, one)

    three =
      ns[:"5"]
      |> Enum.filter(fn c ->
        MapSet.intersection(one, c) == one
      end)
      |> hd

    five =
      ns[:"5"]
      |> Enum.filter(fn c ->
        MapSet.intersection(bd, c) == bd
      end)
      |> hd

    two =
      ns[:"5"]
      |> Enum.filter(fn c ->
        c != five && c != three
      end)
      |> hd

    nine =
      ns[:"6"]
      |> Enum.filter(fn c ->
        MapSet.intersection(c, four) == four
      end)
      |> hd

    zero =
      ns[:"6"]
      |> Enum.filter(fn c ->
        MapSet.intersection(c, one) == one and c != nine
      end)
      |> hd

    six =
      ns[:"6"]
      |> Enum.filter(fn c ->
        c != zero and c != nine
      end)
      |> hd

    %{
      zero => 0,
      one => 1,
      two => 2,
      three => 3,
      four => 4,
      five => 5,
      six => 6,
      seven => 7,
      eight => 8,
      nine => 9
    }
  end

  def segment2number(query, segments) do
    set = query |> String.split("", trim: true) |> MapSet.new()
    segments[set]
  end

  def translate_output(output, segments) do
    output
    |> Enum.map(fn segment ->
      segment2number(segment, segments)
      |> to_string
    end)
  end

  def part_i do
    data = read_and_parse("lib/Q8/data")

    data
    |> Enum.reduce(
      0,
      fn {_input, output}, acc ->
        n =
          Enum.map(output, &String.length/1)
          |> Enum.filter(fn x -> x in [2, 3, 4, 7] end)
          |> length

        acc + n
      end
    )
  end

  def part_ii do
    data = read_and_parse("lib/Q8/data")

    data
    |> Enum.map(fn {input, output} ->
      segments = train(input)

      output
      |> translate_output(segments)
      |> List.to_string()
      |> String.to_integer()
    end)
    |> Enum.sum()
  end
end
