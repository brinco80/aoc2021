defmodule Q10 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    data_str
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.split("", trim: true)
    end)
  end

  def check_line(line) do
    line
    |> Enum.reduce_while(
      [],
      fn token, acc ->
        case token do
          token when token in ["(", "[", "{", "<"] ->
            {:cont, List.insert_at(acc, 0, token)}

          _ ->
            {val, acc} = List.pop_at(acc, 0)

            case token do
              "]" ->
                if val == "[",
                  do: {:cont, acc},
                  else: {:halt, {token, "Expected #{val} found #{token}"}}

              ")" ->
                if val == "(",
                  do: {:cont, acc},
                  else: {:halt, {token, "Expected #{val} found #{token}"}}

              "}" ->
                if val == "{",
                  do: {:cont, acc},
                  else: {:halt, {token, "Expected #{val} found #{token}"}}

              ">" ->
                if val == "<",
                  do: {:cont, acc},
                  else: {:halt, {token, "Expected #{val} found #{token}"}}

              _ ->
                {:halt, {token, "Unexpected token #{token}"}}
            end
        end
      end
    )
  end

  def part_i do
    data = read_and_parse("lib/Q10/data")

    map_val = %{
      ")" => 3,
      "]" => 57,
      "}" => 1197,
      ">" => 25137
    }

    data
    |> Enum.map(&check_line/1)
    |> Enum.filter(&is_tuple/1)
    |> Enum.reduce(
      0,
      fn {token, _}, acc ->
        acc + map_val[token]
      end
    )
  end

  def part_ii do
    data = read_and_parse("lib/Q10/data")

    map_val = %{
      "(" => 1,
      "[" => 2,
      "{" => 3,
      "<" => 4
    }

    scores =
      data
      |> Enum.map(&check_line/1)
      |> Enum.filter(&is_list/1)
      #  |> Enum.map(&Enum.reverse/1) |> IO.inspect()
      |> Enum.map(fn tokens ->
        tokens
        |> Enum.reduce(
          0,
          fn token, acc ->
            5 * acc + map_val[token]
          end
        )
      end)
      |> Enum.sort()
      |> IO.inspect()

    score_length = length(scores)
    idx = div(score_length, 2)

    Enum.at(scores, idx)
  end
end
