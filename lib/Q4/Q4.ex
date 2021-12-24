defmodule Q4 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to lines
    lines = data_str |> String.split("\n") |>
      Enum.filter( fn x -> x != "" end)

    number_list = hd(lines) |> String.split(",") |> Enum.map(&String.to_integer/1)
    boards = tl(lines) |>
      Enum.map(fn row -> String.split(row ," ") |>
      Enum.filter( fn x -> x != "" end) |>
      Enum.map(&String.to_integer/1) end) |>
      Enum.chunk_every(5) |>
      Enum.map(&Enum.concat/1)

    {number_list, boards}
  end

  def get_cols(board,  length) do
    0..length-1 |>
      Enum.map(
        fn j ->
          0..length-1 |> Enum.map( fn i -> Enum.at(board, i*length + j) end )
      end)
  end


  def get_rows(board,  length) do
    board |> Enum.chunk_every(length)
  end


  def update_state(new_number, %{numbers: ns, boards: bs, last_bingo: nb}) do
    ns = List.insert_at(ns, 0, new_number)

    n_atom = to_string(new_number) |> String.to_atom
    # update state
    boards = bs |> Enum.map(
      fn b ->
        case b[:bingo] do
          true -> b
          _ ->
            status = b[:status]
            status = Keyword.replace(status, n_atom, true)
            Map.put(b, :status, status)
        end
      end
    )

    # check if bingo!!
    boards = boards |> Enum.map(
      fn b ->
        case b do
          %{:bingo => true} -> # check only non bingo boards
            b
          _ ->
            # cols check
            keys = Keyword.keys(b[:status])

            cols =  keys |> get_cols(5)
            col_bingo = Enum.map(cols,
              fn col ->
                col |> Enum.map(fn id -> b[:status][id] end) |> Enum.all?
              end
            ) |> Enum.any?

            # rows check
            rows = keys |> get_rows(5)
            row_bingo = Enum.map(rows,
              fn col ->
                col |> Enum.map(fn id -> b[:status][id] end) |> Enum.all?
              end
            ) |> Enum.any?

            if row_bingo || col_bingo do
#              IO.puts("Bingo! with number #{new_number}")
              %{b | order: nb, bingo: true, bingo_number: new_number} #|> IO.inspect

            else b
            end
        end
      end
    )

    # update bingo_number
    nb = boards |> Enum.reduce(0, fn b, acc -> if b[:bingo], do: acc + 1, else: acc end )

    %{
      numbers: ns,
      boards: boards,
      last_bingo: nb
    }
  end

  def is_bingo?(state) do
    state[:boards]
    |> Enum.reduce_while({false, nil}, fn b, _acc ->
      if b[:bingo] do
        {:halt, {:true, b}}
      else
        {:cont, {:false, b}}
      end
    end)
  end





  def initialize_state(board_list) do
    boards = board_list |> Enum.map(
      fn b ->
        status = b |> Enum.map(fn id -> {id |> Integer.to_string |> String.to_atom, false} end) |> Keyword.new
        %{status: status, bingo: false, order: nil, bingo_number: nil}
      end
    )

    %{
      numbers: [],
      boards: boards,
      last_bingo: 0
    }
  end

  def part_i do
    {ns, bs} = read_and_parse("lib/Q4/data")

    state = initialize_state(bs)

    winner = ns |> Enum.reduce_while({nil, state},
      fn n, {_, state} ->
        state = update_state(n, state)

        case is_bingo?(state) do
          {true, board} -> {:halt, {board, state}}
          _ -> {:cont, {nil, state}}
        end

      end
    )

    case winner do
      {nil, _state} ->
        IO.puts("No winner")
        {0,0,0}
      {board, state} ->

        number = hd(state[:numbers])
        IO.puts("Last number #{number} ")
        IO.puts("Winner board")
        IO.inspect(board)
        win = board[:status]
        |> Enum.reduce(0, fn {i, val}, acc -> if(!val, do: acc + (to_string(i) |> String.to_integer), else: acc)  end)
        {win, number, win*number}
    end
  end


  def part_ii do
    {ns, bs} = read_and_parse("lib/Q4/data")

    state = initialize_state(bs)

    state = ns |> Enum.reduce(state,
      fn n, state ->
        update_state(n, state)
      end
    )

    n_boards = length(bs)

    last_board = state[:boards] |> Enum.filter(
      fn %{order: n} ->
        n == (n_boards-1)
      end
    ) |> hd


    IO.puts("Last number #{last_board[:bingo_number]} ")
    IO.puts("Winner board")
    IO.inspect(last_board)

    win = last_board[:status]
    |> Enum.reduce(0, fn {i, val}, acc -> if(!val, do: acc + (to_string(i) |> String.to_integer), else: acc)  end)
    {win, last_board[:bingo_number], win*last_board[:bingo_number]}

  end

end
