defmodule Q18 do

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    data_str
    |> String.split("\n", trim: true)
    |> Enum.map(
      fn l ->
        {n, _} = Code.eval_string(l)
        n
      end
    )
  end


  def snail_sum(a,b), do: [a,b] |> reduce

  def reduce(x) do
    y = explode(x)

    case y do
      ^x = y ->  # number don't change
        z = split(y)
        if z == y, do: z, else: reduce(z)
      _ -> reduce(y) # keep reducing
    end
  end


  def left_add(a, c) when is_integer(a), do: a+c
  def left_add([a,b], c) when is_integer(a), do: [a+c,b]
  def left_add([a,b], c), do: [left_add(a,c),b]

  def right_add(a, c) when is_integer(a), do: a+c
  def right_add([a,b], c) when is_integer(b), do: [a,b+c]
  def right_add([a,b], c), do: [a, right_add(b,c)]

  def explode( [[[[[_a1111,a1112],a112],a12],a2],b] ), do: [[[[0,left_add(a112,a1112)],a12],a2],b]
  def explode( [[[[a111,[a1121, a1122]],a12],a2],b] ), do: [[[[right_add(a111,a1121),0],left_add(a12, a1122)],a2],b]
  def explode( [[[a11,[[a1211,a1212], a122]],a2],b] ), do: [[[right_add(a11,a1211),[0, left_add(a122,a1212)]] ,a2],b]
  def explode( [[[a11,[a121, [a1221,a1222]]],a2],b] ), do: [[[a11,[right_add(a121,a1221), 0]],left_add(a2,a1222)],b]
  def explode( [[a1,[[[a2111,a2112], a212], a22]],b]), do: [[right_add(a1,a2111),[[0, left_add(a212,a2112)], a22]],b]
  def explode( [[a1,[[a211, [a2121,a2122]], a22]],b]), do: [[a1,[[right_add(a211,a2121), 0], left_add(a22,a2122)]],b]
  def explode( [[a1,[a21, [[a2211,a2212],a222]]],b]),  do: [[a1,[right_add(a21,a2211), [0,left_add(a222,a2212)]]],b]
  def explode( [[a1,[a21, [a221,[a2221,a2222]]]],b]),  do: [[a1,[a21, [right_add(a221,a2221),0]]],left_add(b,a2222)]

  def explode( [a,[[[[b1111,b1112],b112],b12],b2]] ), do: [right_add(a, b1111), [[[0,left_add(b112,b1112)],b12],b2]]
  def explode( [a,[[[b111,[b1121, b1122]],b12],b2]] ), do: [a, [[[right_add(b111,b1121),0],left_add(b12, b1122)],b2]]
  def explode( [a, [[b11,[[b1211,b1212], b122]],b2]] ), do: [a, [[right_add(b11,b1211),[0, left_add(b122,b1212)]] ,b2]]
  def explode( [a, [[b11,[b121, [b1221,b1222]]],b2]] ), do: [a, [[b11,[right_add(b121,b1221), 0]],left_add(b2,b1222)]]
  def explode( [a, [b1,[[[b2111,b2112], b212], b22]]]), do: [a, [right_add(b1,b2111),[[0, left_add(b212,b2112)], b22]]]
  def explode( [a,[b1,[[b211, [b2121,b2122]], b22]]]), do: [a, [b1,[[right_add(b211,b2121), 0], left_add(b22,b2122)]]]
  def explode( [a,[b1,[b21, [[b2211,b2212],b222]]]]),  do: [a, [b1,[right_add(b21,b2211), [0,left_add(b222,b2212)]]]]
  def explode( [a,[b1,[b21, [b221,[b2221,_b2222]]]]]),  do: [a, [b1,[b21, [right_add(b221,b2221),0]]]]


  def explode([a,b]), do: [a,b]

  def split(a) when is_integer(a) do
    if a>9, do: [floor(a/2), ceil(a/2)], else: a
  end

  def split([_a,_b] = x) do
    case x do
      [a,b] when is_integer(a) ->
        if a > 9, do: [[floor(a/2), ceil(a/2)], b], else: [a,split(b)]
      [a,b] when is_list(a) ->
        x = split(a)
        if x != a, do: [x,b], else: [a, split(b)]
      [a,b] when is_integer(b) ->
        if b > 9, do: [a, [floor(b/2), ceil(b/2)]], else: [a,b]
      [a,b] when is_list(b) ->
        [a, split(b)]
    end
  end


  def magnitude(a) when is_integer(a), do: a
  def magnitude([a,b]) do
    3*magnitude(a) + 2*magnitude(b)
  end

  def snail_sum_list(numbers) do
    [n0 | ns] = numbers

    ns
    |> Enum.reduce(n0,
      fn n, acc ->
        snail_sum(acc,n)
      end
    )
  end

  def part_i(filename \\ "lib/Q18/test") do
    numbers = read_and_parse(filename) |> IO.inspect()

    snail_sum_list(numbers)
    |> magnitude()
  end

  def part_ii(filename \\ "lib/Q18/test") do
    numbers = read_and_parse(filename) |> IO.inspect()

    numbers
    |> Enum.flat_map(
      fn x ->
        numbers
        |> Enum.map(
          fn y ->
            [x,y]
          end
        )
      end
    )
    |> Enum.filter(fn [a,b] -> a != b end)
    |> Enum.reduce({0, [], []},
      fn [a,b], {current_max, _a_max, _b_max} = acc ->
        m_fwd = snail_sum(a,b) |> magnitude()
        m_inv = snail_sum(b,a) |> magnitude()

        new_acc = if m_fwd > current_max, do: {m_fwd, a, b}, else:  acc
        if m_inv > elem(new_acc,2), do: {m_inv, b, a}, else: new_acc

      end

    )
  end

end
