defmodule Q21 do
  require Integer

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n", trim: true)
    |> Enum.map(
      fn line ->
        [_player, p0] = Regex.run(~r/Player (\d) starting position: (\d+)/, line)
        |> tl
        |> Enum.map(&String.to_integer/1)
        p0
      end
    )
#    |> Map.new
  end

  # this problem has a modulo logic (not-so) hidden
  # it's easier to model it using the following equations
  # p(i+1) = p(i) + d(i) mod 10
  # s(i+1) = s(i) + p(i+1) + 1
  # where c(i) is the pawn position minus one at turn i
  # s(i) is the score after turn i
  # d(i) is the die output at turn i

  # also for part i die can be modelled as (~ is congruent)
  # d(i) = k(i)-1 mod 100 + k(i) mod 100 + k(i)+ 1 mod 100 + 3
  #      ~ 3*k(i) mod 100 + 3
  #      ~ 3*k(i)+3 mod 10
  #      ~ 9*i -3 mod 10  (I don't know how to justifu this step but it works)
  # where k(i) is the starting number at turn i

  # k(i) can be modelled as
  # k(i) = 3*i-2 for i < 33
  # k(i) = 3*i-1 for

  def deterministic_die(i), do: Integer.mod(9*i-3,10)

  def dirac_die_freq() do
    %{
#       1 => 2,
#       2 => 1,
      3 => 1,
      4 => 3,
      5 => 6,
      6 => 7,
      7 => 6,
      8 => 3,
      9 => 1,
    }
  end

  def next_position(position, die), do: Integer.mod(position + die, 10)

  def next_score(score, next_position), do: score + next_position + 1

  def _play(die, position, score) do
    p = next_position(position, die)
    {p, next_score(score, p)}
  end

  def play(die, %{turn: t} = state) do
    {p,s} = state[t]
    new_play = _play(die, p, s)

    state
    |> Map.put(t, new_play)
    |> Map.put(:turn, if(t == :p1, do: :p2, else: :p1))
  end


  def game_state_to_string(%{turn: t, p1: {p1,s1}, p2: {p2, s2}}) do
    "[P1 #{p1+1} #{s1}] [P2 #{p2+1} #{s2}] Next turn #{t}"
  end

  def quantum_search(state, goal) do
    #IO.puts("Enter new level")
    %{game: game_state, search: [w1, w2], mult: q, depth: d} = state

    # For each die combination search rescursively until someone wins
    dirac_die_freq() |>
    Enum.reduce([w1, w2],
      fn {die, freq}, [acc_w1, acc_w2]  ->
        # play the game!
        new_game_state = play(die, game_state)


        case new_game_state do
          %{p1: {_p, s}} when s >= goal ->  # player 1 wins
            [acc_w1+freq*q, acc_w2] # add wins with unused weights
          %{p2: {_p, s}} when s >= goal ->  # player 2 wins
            [acc_w1, acc_w2+freq*q] # add wins with unused weights
          _ -> # keep playing, update game_state and increase multiplier
            #IO.puts("Going deeper!")
            quantum_search(%{game: new_game_state, search: [acc_w1, acc_w2], mult: q*freq, depth: d+1}, goal)
        end
      end
    )
  end


  def part_i(filename \\ "lib/Q21/test") do
    [p10, p20] = read_and_parse(filename)

    state0 = %{p1: {p10-1, 0}, p2: {p20-1, 0}, turn: :p1}

    1..10_000
    |> Enum.reduce_while(state0,
      fn turn, state ->
        new_state = deterministic_die(turn) |> play(state)

        case new_state do
          %{p1: {_p1, s1}, p2: {_p2, s2}} when s1 >= 1000 ->
            IO.puts("Player 1 wins at play #{turn}")
            IO.puts("solution: #{3*turn*s2}")
            {:halt, new_state}
          %{p1: {_p1, s1}, p2: {_p2, s2}} when s2 >= 1000 ->
            IO.puts("Player 2 wins at play #{turn}")
            IO.puts("solution: #{3*turn*s1}")
            {:halt, new_state}
          _ ->
            {:cont, new_state}
        end
      end
    )
  end

  def part_ii(filename \\ "lib/Q21/test") do
    [p10, p20] = read_and_parse(filename)

    game_state0 = %{p1: {p10-1, 0}, p2: {p20-1, 0}, turn: :p1}
    game_state0 |> game_state_to_string() |> IO.puts()

    state0 = %{game: game_state0, search: [0, 0], mult: 1, depth: 0}

    quantum_search(state0, 21)
  end
end
