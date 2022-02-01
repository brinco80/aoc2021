defmodule Q14 do
  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    # convert string to integers
    [chain, rules] =
      data_str
      |> String.split("\n\n", trim: true)

    chain =
      chain
      |> String.split("", trim: true)

    rules =
      rules
      |> String.split("\n", trim: true)
      |> Enum.map(fn f ->
        [key, val] =
          Regex.run(~r/(..) -> (.)/, f)
          |> tl

        {key, val}
      end)
      |> Map.new()

    # rules_rev = rules |> Enum.map(fn {k,v} -> {String.reverse(k), v} end)

    {chain, rules}
  end

  def apply_rules(chain, rules) do
    chain
    |> Enum.reduce(
      {[], ""},
      fn code, {acc, prev} ->
        pair = prev <> code

        if rules[pair] do
          {[code | [rules[pair] | acc]], code}
        else
          {[code | acc], code}
        end
      end
    )
    |> elem(0)
    |> Enum.reverse()
  end

  def apply_rules2({chain, rev}, rules) do
    new_chain =
      chain
      |> Enum.reduce(
        {[], ""},
        fn code, {acc, prev} ->
          pair = if rev, do: code <> prev, else: prev <> code
          extra_code = rules[pair]

          if extra_code do
            {[code | [extra_code | acc]], code}
          else
            {[code | acc], code}
          end
        end
      )
      |> elem(0)

    new_rev = if rev, do: false, else: true

    {new_chain, new_rev}
  end

  def grow_chain(seed, rules, n) do
    0..(n - 1)
    |> Enum.reduce(
      {seed, false},
      fn i, acc ->
        {t, acc} = :timer.tc(fn -> apply_rules2(acc, rules) end)
        {ch, _} = acc
        IO.puts("Chain size at #{i} #{length(ch)}")
        IO.puts("Step #{i} done in #{t / 1_000_000}")
        acc
      end
    )
    |> elem(0)
  end

  def pair_increments(rules) do
    rules
    |> Enum.map(fn {k, v} ->
      [x, y] = k |> String.split("", trim: true)

      left_comb = x <> v
      right_comb = v <> y

      deltas =
        case k do
          ^left_comb -> [{right_comb, 1}]
          ^right_comb -> [{left_comb, 1}]
          _ -> [{k, -1}, {x <> v, 1}, {v <> y, 1}]
        end

      {k, Map.new(deltas)}
    end)
    |> Map.new()
  end

  def part_i(file, n) do
    {chain, rules} = read_and_parse(file)

    chain =
      0..(n - 1)
      |> Enum.reduce(
        {chain, false},
        fn i, acc ->
          {t, acc} = :timer.tc(fn -> apply_rules2(acc, rules) end)
          IO.puts("Step #{i} done in #{t / 1_000_000}")
          acc
        end
      )
      |> elem(0)
      |> IO.inspect()
      |> Enum.frequencies()
      |> IO.inspect()

    max_val =
      chain
      |> Map.values()
      |> Enum.max()

    min_val =
      chain
      |> Map.values()
      |> Enum.min()

    max_val - min_val
  end

  def init_counts(template) do
    template
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn x -> {Enum.join(x), 1} end)
    |> Enum.reduce(%{}, fn {pair, val}, acc -> Map.update(acc, pair, val, &(&1 + val)) end)
  end

  def counts_update(counts, rules_increments) do
    counts
    |> Enum.reduce(
      counts,
      fn {k, v}, acc ->
        case rules_increments[k] do
          nil ->
            acc

          increments ->
            increments
            |> Enum.reduce(
              acc,
              fn {inc_k, inc_v}, acc ->
                Map.update(acc, inc_k, v * 1, fn val -> val + v * inc_v end)
              end
            )
        end
      end
    )
  end

  def part_ii(file, n) do
    {template, rules} = read_and_parse(file)

    start_code = hd(template)

    rules_increments =
      pair_increments(rules)
      |> IO.inspect()

    counts0 = init_counts(template) |> IO.inspect()

    code_counts =
      0..(n - 1)
      |> Enum.reduce(
        counts0,
        fn _i, acc ->
          counts_update(acc, rules_increments)
        end
      )
      |> IO.inspect()
      |> Enum.reduce(
        %{},
        fn {pair, count}, acc ->
          [_a, b] = String.split(pair, "", trim: true)

          Map.update(acc, b, count, &(&1 + count))
        end
      )
      |> Map.update(start_code, 1, &(&1 + 1))
      |> IO.inspect()

    max_val =
      code_counts
      |> Map.values()
      |> Enum.max()

    min_val =
      code_counts
      |> Map.values()
      |> Enum.min()

    max_val - min_val
  end
end
