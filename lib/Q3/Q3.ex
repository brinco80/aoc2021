defmodule Q3 do

  import Bitwise


  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to lines
    data_str |> String.split("\n") |>
      Enum.filter( fn x -> x != "" end)
  end

  def part_i do
    lines = read_and_parse("lib/Q3/data")

    word_length = lines |> hd |> String.length
    numbers_list = lines |>
      Enum.map( fn x-> x |> String.to_integer(2) end )


    [mcb: mcb, lcb: lcb] = xcb(numbers_list, word_length)

    gamma_rate = mcb
      |> Enum.with_index
      |> Enum.map(
        fn {d, i} ->
          d <<< i
        end
      )
      |> Enum.sum

    epsilon_rate = lcb
      |> Enum.with_index
      |> Enum.map(
        fn {d, i} ->
          d <<< i
        end
      )
      |> Enum.sum


    {gamma_rate, epsilon_rate, gamma_rate*epsilon_rate}
  end


  def bit_freq(number_list, bit) do
#    n_lines = length(number_list)

    number_list
    |> Enum.reduce(0,
      fn n, acc ->
        (n &&& (1 <<< bit)) + acc
    end) >>> bit
  end


  def xcb(numbers_list, word_length) do
    n_lines = length(numbers_list)

    bits_freq = 0..word_length-1 |> Enum.map(
      fn  i ->
        bit_freq(numbers_list, i)
      end)

    mcb = bits_freq |> Enum.map( fn x -> if(x/n_lines>=0.5, do: 1, else: 0) end)
    lcb = bits_freq |> Enum.map( fn x -> if(x/n_lines<=0.5, do: 1, else: 0) end)

    [mcb: mcb, lcb: lcb]
  end


  def part_ii do
    lines = read_and_parse("lib/Q3/data")

    word_length = lines |> hd |> String.length
    number_list = lines |>
      Enum.map( fn x-> x |> String.to_integer(2) end )

    o2 = 0..word_length-1
    |> Enum.reverse
    |> Enum.reduce_while(number_list,
      fn i, acc ->
        case acc do
          [x] -> {:halt, [x]}
          _ ->
            freq = acc |> bit_freq(i) #|> IO.inspect
            n_lines = length(acc)

            d = if(freq/n_lines >= 0.5, do: 1, else: 0)
            acc = acc |> Enum.filter(fn n -> ((n &&& (1 <<< i )) >>> i) == d  end) #|> IO.inspect
            {:cont, acc}
        end
      end) |> hd

    co2 = 0..word_length-1
      |> Enum.reverse
      |> Enum.reduce_while(number_list,
        fn i, acc ->
          case acc do
            [x] -> {:halt, [x]}
            _ ->
              freq = acc |> bit_freq(i)
              n_lines = length(acc)

              d = if(freq/n_lines < 0.5, do: 1, else: 0)
              acc = acc |> Enum.filter(fn n -> ((n &&& (1 <<< i )) >>> i) == d  end)
              {:cont, acc}
          end
        end) |> hd

      {o2, co2, o2*co2}

#    oxygen = mcb |> Enum.with_index |> Enum.reverse |> Enum.reduce_while(numbers,
#      fn {d, i}, acc ->
#        case acc do
#          [x] -> {:halt, x}
#          _ ->
#            acc = acc |> Enum.filter(fn n -> ((n &&& (1 <<< i )) >>> i) == d  end)
#            {:cont, acc}
#        end
#      end
#    )


    # co2 = lcb |> Enum.with_index |> Enum.reverse |> Enum.reduce_while(numbers,
    #   fn {d, i}, acc ->
    #     case acc do
    #       [x] -> {:halt, x}
    #       _ ->
    #         acc = acc |> Enum.filter(fn n -> ((n &&& (1 <<< i )) >>> i) == d  end)
    #         {:cont, acc}
    #     end
    #   end
    # )

    # oxygen*co2


  end

end
