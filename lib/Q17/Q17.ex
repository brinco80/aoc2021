defmodule Q17 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    parse_target_area(data_str)

  end

  def parse_target_area(text) do
    [x_min, x_max, y_min, y_max] = Regex.run(~r/target area: x=(\d+)\.\.(\d+), y=([-\d]+)\.\.([-\d]+)/, text)
    |> tl
    |> Enum.map(&String.to_integer/1)

    %{x_min: x_min, x_max: x_max, y_min: y_min, y_max: y_max}
  end

  def sign(x) when x>0, do: 1
  def sign(x) when x==0, do: 0
  def sign(x) when x<0, do: -1


  def probe_dynamics({{x,y}, {vx,vy}}) do
    x = x + vx
    y = y + vy

    vx = vx - sign(vx)
    vy = vy - 1

    {{x,y}, {vx,vy}}
  end

  def simulation(init_state, %{x_min: x_min, x_max: x_max, y_min: y_min, y_max: y_max} = _target_area, n) do
    0..n-1
    |> Enum.reduce_while([{init_state, false}],
      fn _t, [{state, _} | _] = acc ->
        new_state = probe_dynamics(state)

        {{x,y},_} = new_state

          # check if i am within target area
        is_target_area = (x >= x_min && x <= x_max && y >= y_min && y <=y_max)
        new_acc = [{new_state, is_target_area} | acc ]

        if y < y_min || is_target_area do # I can't reach target area anymore or I already reached
          {:halt, new_acc}
        else
          {:cont, new_acc}
        end


      end
    )
    |> Enum.reverse()
  end


  def max_height(v0, target_area, n) do
    sim = simulation({{0,0},v0}, target_area, n)

    success = sim
    |> Enum.any?(fn {_state, x} -> x end)

    if success do
      sim
      |> Enum.with_index()
      |> Enum.map( fn { {{{_x,y}, _v}, _}, _t } -> y end)
      |> Enum.max()

    else
      nil
    end
  end


  def get_neighbors({x0,y0}, n) do
    0..n
    |> Enum.flat_map(
      fn x ->
        0..n
        |> Enum.flat_map(
          fn y ->
            [{x0 + x, y0 + y}, {x0 - x, y0 - y}]
          end
        )
      end
    )
    |> Enum.filter(fn p -> p != {x0,y0} end)
  end

  def y_estimation(y, vy) do
    t = (2*vy+1 + :math.sqrt( :math.pow(2*(vy+1),2) - 8*y))/2

    tp1 = ceil(t)
    tm1 = floor(t)

    yp1 =y_traj(tp1, vy)
    ym1 =y_traj(tm1, vy)

    {{tm1, ym1}, {tp1, yp1}}
  end

  def y_traj(k, vy) do
    1/2*k*(2*vy-k+1)
  end

  def random_guess(%{x_min: x_min, x_max: _x_max, y_min: y_min, y_max: _y_max} = target_area, n_sim, n_trials) do
    maxX = x_min
    maxY = abs(y_min)


    0..n_trials
    |> Enum.reduce_while([],
      fn _i, _acc ->
        v_guess = {round(:rand.uniform*maxX), round(:rand.uniform*maxY)}
        y = max_height(v_guess, target_area, n_sim)

        if is_nil(y), do: {:cont, {}}, else: {:halt, v_guess}
      end
    )
  end

  # part_i(1000, 50, "lib/Q17/data")
  def part_i(n_sim, n_neigh,  filename \\ "lib/Q17/test") do
    target_area = read_and_parse(filename)

    IO.puts("Random guess")
    vi = random_guess(target_area, n_sim, 500) |> IO.inspect()

    f = fn v ->  max_height(v, target_area, n_sim)  end
#    yi = f.(vi)


    Stream.cycle([0])
    |> Enum.reduce_while({vi,0},
      fn _i, {v0, y_max_old} ->
        {p, y_max} = get_neighbors(v0, n_neigh)
        |> Enum.map(
          fn v ->
            y = f.(v)
            if is_nil(y), do: {v, -1000}, else: {v, f.(v)}
          end
        )
        |> Enum.max_by(fn {_p, y} ->  y end)

        if y_max > y_max_old, do: {:cont, {p, y_max}}, else: {:halt, {v0, y_max}}
      end
    )
  end


  def part_ii(n_sim, n_max, filename \\ "lib/Q17/test") do
    target_area = read_and_parse(filename)

    # search grid
    grid = 0..n_max |>
    Enum.flat_map(
      fn x ->
        -n_max..n_max
        |> Enum.map(
          fn y ->
            {x,y}
          end
        )
      end
    )

    f = fn v ->  max_height(v, target_area, n_sim)  end

    # brute force search
    grid
    |> Enum.map(f)
    |> Enum.filter(&(&1))
    |> length()

  end

end
