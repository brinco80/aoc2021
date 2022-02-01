defmodule Q19 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n\n", trim: true)
    |> Enum.with_index()
    |> Enum.map(fn {l, i} ->
      beacons =
        l
        |> String.split("\n", trim: true)
        # remove header
        |> tl
        |> Enum.with_index()
        |> Enum.map(fn {tuple, i} ->
          coords =
            tuple
            |> String.split(",", trim: true)
            |> Enum.map(&String.to_integer/1)
            |> List.to_tuple()

          {i, coords}
        end)
        |> Map.new()

      {i, beacons}
    end)
    |> Map.new()
  end

  def vector_difference(a, b) do
    n = tuple_size(a)

    0..(n - 1)
    |> Enum.map(fn i ->
      elem(a, i) - elem(b, i)
    end)
    |> List.to_tuple()
  end

  def vector_addition(a, b) do
    n = tuple_size(a)

    0..(n - 1)
    |> Enum.map(fn i ->
      elem(a, i) + elem(b, i)
    end)
    |> List.to_tuple()
  end

  def distance(a, b) do
    n = tuple_size(a)

    0..(n - 1)
    |> Enum.reduce(
      0,
      fn i, acc ->
        acc + (elem(a, i) - elem(b, i)) * (elem(a, i) - elem(b, i))
      end
    )
    |> :math.sqrt()
  end

  def sort_id({from, to}) when from < to, do: {from, to}
  def sort_id({from, to}), do: {to, from}

  def do_compute_distances([{_id_from, _p_from} | []], acc), do: acc

  def do_compute_distances([{id_from, p_from} | rest], acc) do
    ds =
      rest
      |> Enum.map(fn {id, p} ->
        {sort_id({id_from, id}), distance(p_from, p)}
      end)

    do_compute_distances(rest, ds ++ acc)
  end

  def compute_distances(beacons) do
    beacons
    |> Map.to_list()
    |> do_compute_distances([])
    |> Map.new()
  end

  def compute_all_distances_full(measurements) do
    measurements
    |> Map.map(fn {_id, ds} ->
      compute_distances(ds)
    end)
  end

  # I'm assuming each pair of points has a different distance
  # Find pairs with similar distance
  def find_similar_points_by_distance(distances1, distances2) do
    distances1
    |> Enum.map(fn {id1, d1} ->
      case distances2 |> Enum.find(fn {_id, d} -> d == d1 end) do
        {id2, _d} -> {id1, id2}
        _ -> nil
      end
    end)
    |> Enum.filter(fn x -> x end)
  end

  def equivalent_beacons(pair_list) do
    chunks =
      pair_list
      |> Enum.sort()
      |> Enum.chunk_by(fn {{a1, _}, _} -> a1 end)
      |> Enum.sort_by(&(-length(&1)))

    # for each chunk find pairs sort them by repetition and
    # match beacons with equal number
    chunks
    |> Enum.reduce(
      [],
      fn c, acc ->
        c_l = length(c)

        [{{src, _}, _} | _] = c

        if c_l > 1 do
          tgt =
            c
            |> Enum.flat_map(fn {_, {b1, b2}} -> [b1, b2] end)
            |> Enum.frequencies()
            |> Enum.find(fn {_k, v} -> v == c_l end)
            |> elem(0)

          # match other pair
          next_tgt =
            c
            |> Enum.map(fn {{_a1, a2}, b} ->
              case b do
                {^tgt, x} -> {a2, x}
                {x, ^tgt} -> {a2, x}
              end
            end)

          [{src, tgt} | acc] ++ next_tgt
        else
          [{{src, to}, {src2, to2}}] = c

          conversion = Map.new(acc)

          case conversion[src] do
            ^src2 -> [{to, to2} | acc]
            ^to2 -> [{to, src2} | acc]
            _ -> acc
          end
        end
      end
    )
    |> Enum.sort()
    |> Enum.uniq()
  end

  def sign(x) when x > 0, do: 1
  def sign(x) when x < 0, do: -1
  def sign(0), do: 0

  def rotate(x, rotation) do
    n = tuple_size(x)
    #    rotation |> IO.inspect()
    x_rot = 0..(n - 1) |> Enum.map(& &1)

    x
    |> Tuple.to_list()
    |> Enum.with_index()
    |> Enum.reduce(
      x_rot,
      fn {x_i, i}, acc ->
        {j, s} = rotation[i]
        List.replace_at(acc, j, s * x_i)
      end
    )
    |> List.to_tuple()
  end

  def rotation_ik(rotation_ij, rotation_jk) do
    rotation_jk
    |> Map.map(fn {_k, {j, sj}} ->
      {i, si} = rotation_ij[j]
      {i, si * sj}
    end)
  end

  def transformation_ik(%{offset: offset_ij, rotation: rotation_ij}, %{
        offset: offset_jk,
        rotation: rotation_jk
      }) do
    offset_ik = offset_jk |> rotate(rotation_ij) |> vector_addition(offset_ij)
    rotation_ik = rotation_ik(rotation_ij, rotation_jk)
    %{offset: offset_ik, rotation: rotation_ik}
  end

  def inv_rotation(rotation) do
    rotation
    |> Enum.map(fn {i, {j, s}} ->
      {j, {i, s}}
    end)
    |> Map.new()
  end

  def inv_offset(offset_fwd, rotation_inv) do
    minus_offset =
      0..(tuple_size(offset_fwd) - 1)
      |> Enum.map(fn i -> -elem(offset_fwd, i) end)
      |> List.to_tuple()

    rotate(minus_offset, rotation_inv)
  end

  def convert_coordinates(coords, %{offset: offset, rotation: rotation}) do
    coords
    |> Enum.map(fn p ->
      vector_addition(offset, rotate(p, rotation))
    end)
  end

  def compute_rotation(dp, dq) do
    n = tuple_size(dq)

    0..(n - 1)
    |> Enum.reduce(
      [],
      fn i, acc ->
        0..(n - 1)
        |> Enum.reduce(
          acc,
          fn j, acc2 ->
            p_coord = elem(dp, i)
            q_coord = elem(dq, j)

            if abs(p_coord) == abs(q_coord) do
              if sign(p_coord) == sign(q_coord) do
                [{j, 1} | acc2]
              else
                [{j, -1} | acc2]
              end
            else
              acc2
            end
          end
        )
      end
    )
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {{i, s}, k} -> {i, {k, s}} end)
    |> Map.new()
  end

  def transformations_chain({i, j} = key, transformations) do
    case transformations do
      %{^key => _x} ->
        [key]

      _ ->
        # available trx
        available_trx = Map.keys(transformations)

        # select last transformations
        available_trx
        # candidates to match missing links
        |> Enum.filter(fn {_i, k} -> k == j end)
        |> Enum.reduce_while(
          [],
          fn {k, _j}, _acc ->
            test_key = {k, j}
            # add transformation to chain
            acc = [test_key]

            # search for trx {i,k}
            parent_key = {i, k}

            case transformations do
              # found last link: done!
              %{^parent_key => _trx} ->
                {:halt, [parent_key | acc]}

              _ ->
                # no luck, check on deeper level
                # remove current transformations
                new_transformations = Map.drop(transformations, [test_key, {j, k}])

                case transformations_chain({i, k}, new_transformations) do
                  [] ->
                    # no luck! continue ¬¬
                    {:cont, []}

                  chain ->
                    # sucess! concat and stop
                    {:halt, chain ++ acc}
                end
            end
          end
        )
    end
  end

  def fill_transformations(transformations, n_scanners) do
    1..(n_scanners - 1)
    |> Enum.map(fn i ->
      key = {0, i}

      case transformations do
        %{^key => x} ->
          {key, x}

        _ ->
          [last | rest] =
            transformations_chain(key, transformations)
            |> Enum.reverse()

          last_trx = transformations[last]

          trx =
            rest
            |> Enum.reduce(
              last_trx,
              fn t, acc ->
                current_trans = transformations[t]
                transformation_ik(current_trans, acc)
              end
            )

          {key, trx}
      end
    end)
    |> Map.new()
  end

  def select_random_points(equivalence_map, measurements_p, measurements_q) do
    [{p_id0, q_id0}, {p_id1, q_id1} | rest] = equivalence_map

    p0 = measurements_p[p_id0]
    q0 = measurements_q[q_id0]

    p1 = measurements_p[p_id1]
    q1 = measurements_q[q_id1]

    dp = vector_difference(p0, p1)
    dq = vector_difference(q0, q1)

    dp_abs =
      dp
      |> Tuple.to_list()
      |> Enum.map(&abs/1)

    if any_coord_equal(dp_abs) do
      select_random_points(rest, measurements_p, measurements_q)
    else
      {p0, q0, dp, dq}
    end
  end

  def any_coord_equal([]), do: false

  def any_coord_equal([x | rest]) do
    is_equal = rest |> Enum.any?(fn y -> x == y end)

    if is_equal, do: true, else: any_coord_equal(rest)
  end

  def compute_overlaps(measurements, n_overlap) do
    distances = compute_all_distances_full(measurements)

    0..(map_size(distances) - 2)
    |> Enum.flat_map(fn i ->
      (i + 1)..(map_size(distances) - 1)
      |> Enum.flat_map(fn j ->
        # repeat for all scanners (right now is only for first and second ones)
        beacons_equivalence_map =
          find_similar_points_by_distance(distances[i], distances[j])
          |> equivalent_beacons
          |> Map.new()

        if map_size(beacons_equivalence_map) >= n_overlap do
          IO.puts(
            "Scanner #{i} overlaps with #{j} (#{map_size(beacons_equivalence_map)} beacons)"
          )

          {p0, q0, dp, dq} =
            beacons_equivalence_map
            |> Map.to_list()
            |> select_random_points(measurements[i], measurements[j])

          # coordinate mapping
          rotation_fwd = compute_rotation(dp, dq)
          rotation_inv = inv_rotation(rotation_fwd)

          # distance between scanners
          offset_fwd = vector_difference(p0, rotate(q0, rotation_fwd))
          offset_inv = inv_offset(offset_fwd, rotation_inv)

          # coordinates on p reference
          [
            {
              {i, j},
              # fwd transformation
              %{offset: offset_fwd, rotation: rotation_fwd}
            },
            {
              {j, i},
              # inverse transformation
              %{offset: offset_inv, rotation: rotation_inv}
            }
          ]
        else
          # IO.puts("Scanners #{i} doesn't overlap #{j} (#{map_size(matched_beacons_map)} beacons)")
          []
        end
      end)
    end)
    |> Map.new()
  end

  def manhattan_distance(p, q) do
    vector_difference(p, q)
    |> Tuple.to_list()
    |> Enum.map(&abs/1)
    |> Enum.sum()
  end

  def part_i(filename \\ "lib/Q19/test") do
    measurements = read_and_parse(filename)

    n_scanners = map_size(measurements)

    transformations = compute_overlaps(measurements, 12)

    trx_0 = fill_transformations(transformations, n_scanners)

    measurements
    |> Map.map(fn {k, v} ->
      if k != 0 do
        t = trx_0[{0, k}]
        v = Map.values(v)
        convert_coordinates(v, t)
      else
        Map.values(v)
      end
    end)
    |> Map.values()
    |> Enum.concat()
    |> Enum.uniq()
    |> length()
  end

  def part_ii(filename \\ "lib/Q19/test") do
    measurements = read_and_parse(filename)

    n_scanners = map_size(measurements)

    offsets =
      compute_overlaps(measurements, 12)
      |> fill_transformations(n_scanners)
      |> Map.to_list()
      |> Enum.map(fn {{_, k}, %{offset: o}} -> {k, o} end)
      |> List.to_tuple()

    distances =
      0..(n_scanners - 3)
      |> Enum.flat_map(fn i ->
        i..(n_scanners - 2)
        |> Enum.map(fn j ->
          if i == 0 do
            {s2, o2} = elem(offsets, j)
            {manhattan_distance({0, 0, 0}, o2), {0, s2}}
          else
            {s1, o1} = elem(offsets, i)
            {s2, o2} = elem(offsets, j)
            {manhattan_distance(o1, o2), {s1, s2}}
          end
        end)
      end)

    distances
    |> Enum.reduce(
      {-100, nil},
      fn {d, {s1, s2}}, {max, _} = acc ->
        if d >= max do
          {d, {s1, s2}}
        else
          acc
        end
      end
    )
  end
end
