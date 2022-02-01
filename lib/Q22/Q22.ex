defmodule Q22 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n", trim: true)
    |> Enum.map(fn line ->
      [state, coords] = String.split(line, " ", trim: true)

      [["x", x_min, x_max], ["y", y_min, y_max], ["z", z_min, z_max]] =
        coords
        |> String.split(",", trim: true)
        |> Enum.map(
          &(Regex.run(~r/(.)=(-?\d+)..(-?\d+)/, &1)
            |> tl)
        )

      {state, [x_min, y_min, z_min] |> Enum.map(&String.to_integer/1),
       [x_max, y_max, z_max] |> Enum.map(&String.to_integer/1)}
    end)

    #    |> Map.new
  end

  # assumption: x1 <= x2  and y1 <= y2
  def segment_intersection([x1, _x2], [_y1, y2]) when y2 < x1, do: [nil, nil]
  def segment_intersection([_x1, x2], [y1, _y2]) when x2 < y1, do: [nil, nil]

  def segment_intersection([x1, x2], [y1, y2]) do
    [max(x1, y1), min(x2, y2)]
  end

  def square_intersection([[x1, y1], [x2, y2]], [[u1, v1], [u2, v2]]) do
    [z1, z2] = segment_intersection([x1, x2], [u1, u2])
    [v1, v2] = segment_intersection([y1, y2], [v1, v2])

    [
      [z1, v1],
      [z2, v2]
    ]
  end

  def cuboid_intersection([[x1, y1, z1], [x2, y2, z2]], [[u1, v1, w1], [u2, v2, w2]]) do
    [[b1, c1], [b2, c2]] = square_intersection([[y1, z1], [y2, z2]], [[v1, w1], [v2, w2]])
    [[a1, ^c1], [a2, ^c2]] = square_intersection([[x1, z1], [x2, z2]], [[u1, w1], [u2, w2]])

    [
      [a1, b1, c1],
      [a2, b2, c2]
    ]
  end

  def cuboid_corners([[x1, y1, z1], [x2, y2, z2]]) do
    [
      [x1, y1, z1],
      [x1, y2, z1],
      [x2, y2, z1],
      [x2, y1, z1],
      [x1, y1, z2],
      [x1, y2, z2],
      [x2, y2, z2],
      [x2, y1, z2]
    ]
  end

  def is_empty([p, q]) do
    !(Enum.all?(p) or Enum.all?(q))
  end

  def cuboid_size([[p1, p2, p3], [q1, q2, q3]]) do
    (abs(p1 - q1) + 1) * (abs(p2 - q2) + 1) * (abs(p3 - q3) + 1)
  end

  def expand_cubes([[x1, y1, z1], [x2, y2, z2]]) do
    for i <- x1..x2, j <- y1..y2, k <- z1..z2 do
      [i, j, k]
    end
  end

  def not_zero_size([[p11, p12, p13], [p21, p22, p23]]) do
    p11 <= p21 and p12 <= p22 and p13 <= p23
  end

  # split p around r
  def split_cuboid([p1, p2] = p, r) do
    if is_empty(r) do
      p
    else
      [[r11, r12, r13], [r21, r22, r23]] = r
      [_p11, p12, p13] = p1
      [_p21, p22, p23] = p2

      outer_front = [p1, [r11 - 1, p22, p23]]
      middle_left = [[r11, p12, p13], [r21, r12 - 1, p23]]
      middle_bottom = [[r11, r12, p13], [r21, r22, r13 - 1]]
      middle_top = [[r11, r12, r23 + 1], [r21, r22, p23]]
      middle_right = [[r11, r22 + 1, p13], [r21, p22, p23]]
      outer_back = [[r21 + 1, p12, p13], p2]

      # TODO: Filter unfeasible cuboids
      [outer_front, middle_left, middle_bottom, middle_top, middle_right, outer_back]
      |> Enum.filter(&not_zero_size/1)
    end
  end

  def expand_intersection(p, q) do
    r = cuboid_intersection(p, q)

    #    IO.inspect(p, charlists: :as_list)
    #    IO.inspect(q, charlists: :as_list)
    #    IO.inspect(r, charlists: :as_list)

    cond do
      is_empty(r) ->
        #        IO.puts("p disjoint q")
        %{p: [p], q: [q], r: []}

      r == p ->
        #        IO.puts("p subset of q")
        qs = split_cuboid(q, r)
        %{p: [], q: qs, r: [r]}

      r == q ->
        #        IO.puts("q subset of p")
        ps = split_cuboid(p, r)
        %{p: ps, q: [], r: [r]}

      true ->
        #        IO.puts("p inter q")
        ps = split_cuboid(p, r)
        qs = split_cuboid(q, r)

        %{p: ps, q: qs, r: [r]}
    end
  end

  def check_disjoints([]), do: []

  def check_disjoints([p | rest]) do
    invalids =
      for q <- rest do
        if cuboid_intersection(p, q) |> is_empty() do
          []
        else
          [p, q]
        end
      end
      |> Enum.uniq()

    if invalids != [[]] do
      invalids
    else
      check_disjoints(rest)
    end
  end

  # on step
  # I only care about not counting twice
  # to do that new cuboids are decompsed in cuboids that don't contain exitent on_cuboids
  # the remains are added to on_cuboids
  def apply_step({"on", q1, q2}, cuboids) do
    q = [q1, q2]

    qs_rem =
      cuboids
      |> Enum.reduce(
        [q],
        fn c, qs ->
          qs_rem =
            qs
            |> Enum.reduce(
              [],
              fn q, acc ->
                %{p: _ps, q: qs, r: _r} = expand_intersection(c, q)
                acc ++ qs
              end
            )

          # remainder of intersection between all cuboids and all the qs
          qs_rem
        end
      )

    # add remainder to on cuboids
    cuboids ++ qs_rem
  end

  # off step is different and simpler, just remove intersections between on cuboids and q
  # it exploits disjoints between cuboids to work properly
  def apply_step({"off", q1, q2}, cuboids) do
    q = [q1, q2]

    cuboids
    |> Enum.reduce(
      [],
      fn c, on_rem ->
        # ps are active parts of c, and qs is the remainder of q to be applied
        %{p: ps, q: _qs, r: r} = expand_intersection(c, q)

        if r == [] do
          # no inteserction, keep original on_cuboid c
          on_rem ++ [c]
        else
          # intersection, keep parts of the orignal on_cuboid that don't intersect with off cuboid
          on_rem ++ ps
        end
      end
    )
  end

  def add_cuboids([{"on", p1, p2} | rest]) do
    rest
    |> Enum.reduce([[p1, p2]], &apply_step/2)
  end

  def count_cubes(cuboids) do
    cuboids
    |> Enum.map(&cuboid_size/1)
    |> Enum.sum()
  end

  def part_i(filename \\ "lib/Q22/test") do
    steps = read_and_parse(filename)

    universe = [[-50, -50, -50], [50, 50, 50]]

    steps
    |> Enum.reduce(
      MapSet.new(),
      fn {state, p, q}, active_cubes ->
        feasible_zone = cuboid_intersection(universe, [p, q])

        if is_empty(feasible_zone) do
          active_cubes
        else
          cubes =
            expand_cubes(feasible_zone)
            |> MapSet.new()

          if state == "on" do
            active_cubes |> MapSet.union(cubes)
          else
            active_cubes |> MapSet.difference(cubes)
          end
        end
      end
    )
  end

  def part_ii(filename \\ "lib/Q22/test") do
    read_and_parse(filename)
    |> add_cuboids()
    |> count_cubes()
  end
end
