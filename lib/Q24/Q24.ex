defmodule Q24 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n")
    |> Enum.map(
        fn line ->
          [op | args] = line
          |> String.split(" ")

          args = args
          |> Enum.map(
            fn
              arg when arg in ["x", "y", "z", "w"] -> arg
              arg -> String.to_integer(arg)
            end

          )

          {op, args}
        end
    )
  end

  def execute(program, number) do
    state0 = %{"x" => 0, "y" =>  0, "z" => 0, "w" => 0}
    digits = Integer.digits(number)
    program
    |> Enum.reduce({state0, digits},
      fn op, {state, n} -> do_operation(op, n, state) end
    )
  end


  def do_operation({"inp", [var]}, [d | rest], state), do: {%{state | var => d}, rest}
  def do_operation({"add", [x,y]}, n, state) when is_binary(y), do: {%{state | x =>  state[x]+state[y]}, n}
  def do_operation({"add", [x,y]}, n, state), do: {%{state | x =>  state[x]+y}, n}
  def do_operation({"mul", [x,y]}, n, state) when is_binary(y), do: {%{state | x =>  state[x]*state[y]}, n}
  def do_operation({"mul", [x,y]}, n, state), do: {%{state | x =>  state[x]*y}, n}
  def do_operation({"div", [x,y]}, n, state) when is_binary(y), do: {%{state | x =>  div(state[x],state[y])}, n}
  def do_operation({"div", [x,y]}, n, state), do: {%{state | x =>  div(state[x],y)}, n}
  def do_operation({"mod", [x,y]}, n, state) when is_binary(y), do: {%{state | x =>  rem(state[x],state[y])}, n}
  def do_operation({"mod", [x,y]}, n, state), do: {%{state | x =>  rem(state[x],y)}, n}
  def do_operation({"eql", [x,y]}, n, state) when is_binary(y), do: {%{state | x =>  if(state[x]==state[y], do: 1, else: 0)}, n}
  def do_operation({"eql", [x,y]}, n, state), do: {%{state | x =>  if(state[x] ==y, do: 1, else: 0)}, n}



  def part_i(file \\ "lib/Q24/test") do
    program = read_and_parse(file)
    n = 11111111111111*9

    n..11111111111111
    |> Stream.filter( # filter numbers with 0
      fn n ->
        Integer.digits(n) |> Enum.all?( fn d -> d>0 end )
      end
    )
    |> Enum.reduce_while(nil,
      fn n, _ ->
        IO.puts("Test #{n}")
        case execute(program, n) do
          %{"z" => z} when  z==0  -> {:halt, n}
          _ -> {:cont, nil}
        end
      end
    )
  end

  def part_ii(file \\ "lib/Q14/test") do
  end

end
