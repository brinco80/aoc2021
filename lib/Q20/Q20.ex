defmodule Q20 do

  def code2int("#"), do: 1
  def code2int("."), do: 0

  def int2code(1 ,_), do: "#"
  def int2code(0, _), do: "."
  def int2code(nil, default), do: int2code(default, nil)

  def read_and_parse(filename) do
    # read file
    {:ok, data_str} = File.read(filename)

    [enhancement, input] = data_str
    |> String.split("\n\n", trim: true)

    enhancement_map = enhancement
    |> String.split("", trim: true)
    |> Enum.with_index(
      fn el, i -> {i, code2int(el)} end)
    |> Map.new


    input_map = input
    |> String.split("\n")
    |> Enum.with_index(fn element, index -> {index, element} end)
    |> Enum.flat_map(
        fn {x, line} ->
          line
          |> String.split("", trim: true)
          |> Enum.with_index(fn element, index -> {index, code2int(element)} end)
          |> Enum.map(
            fn {y,z} ->
              {{x,y}, z}
            end
          )
        end
      )
    |> Map.new

    image = %{
      data: input_map,
      limits: get_edges(input_map),
      inf_value: 0
    }

    {enhancement_map, image}
  end

  def get_edges(input) do
    input
    |> Map.keys()
    |> Enum.reduce({:inf, :inf, -10000, -10000},
      fn {x,y}, {min_x, min_y, max_x, max_y} ->
        {
          min(min_x, x),
          min(min_y, y),
          max(max_x, x),
          max(max_y, y),
        }
      end
    )
  end

  def get_values(xys, points, inf_value) do
    xys |> Enum.map(
      fn xy ->
        z = points[xy]
        { xy, if(z, do: z, else: inf_value) }
      end
    )
  end

  def get_neighbors_full({x,y}, values, inf_value) do
    (x-1)..(x+1)
    |> Enum.flat_map(
      fn i ->
        (y-1)..(y+1)
        |> Enum.map(
          fn j ->
            {i,j}
          end
        )
      end
    )
    |> get_values(values, inf_value)
  end

  def increase_edges(%{data: data, limits: {x_min, y_min, x_max, y_max}, inf_value: inf}) do
    data = y_min-1..y_max+1
    |> Enum.reduce(data,
      fn y, acc ->
        acc
        |> Map.put_new({x_min-1, y}, inf)
        |> Map.put_new({x_max+1, y}, inf)
      end
    )

    data = x_min..x_max
    |> Enum.reduce(data,
      fn x, acc ->
        acc
        |> Map.put_new({x, y_min-1}, inf)
        |> Map.put_new({x, y_max+1}, inf)
      end
    )

    %{
      data: data,
      limits: {x_min-1, y_min-1, x_max+1, y_max+1},
      inf_value: inf
    }
  end

  def enhance(image, enhance_map) do
    # add max+1 and min-1 to map dimensions
    %{data: data, limits: limits, inf_value: inf} = image
    |> increase_edges()

    data = data |>
    Map.map(
      fn {{x,y}, _v} ->
        #IO.inspect( {x,y})
        index = get_neighbors_full({x,y}, data, inf)  #|> IO.inspect()
        |> Enum.map(fn {_, v} -> if v, do: v, else: inf end)  #|> IO.inspect()
        |> Integer.undigits(2) #|> IO.inspect()

        enhance_map[index]  #|> IO.inspect()
      end
    )

    %{
      data: data,
      limits: limits,
      inf_value: if(inf==0, do: enhance_map[0], else: enhance_map[511])
    }
  end

  def image2string(%{data: data, limits: {x_min, y_min, x_max, y_max}, inf_value: inf}) do
    x_min-2..x_max+2
    |> Enum.map(
      fn x ->
        y_min-2..y_max+2
        |> Enum.map(
          fn y ->
            data[{x,y}] |> int2code(inf)
          end
        )
        |> Enum.join()
      end
    )
    |> Enum.join("\n")
  end

  def inspect_image(image) do
    image |> image2string |> IO.puts()
    IO.puts("\n")
    image
  end


  def part_i(filename \\ "lib/Q20/test") do
    {enhancement, image} = read_and_parse(filename)

    #IO.inspect(image[:limits])

    enhanced_image = image |> inspect_image()
    |> enhance(enhancement) |> inspect_image() #|> IO.inspect()
    |> enhance(enhancement) |> inspect_image()

    enhanced_image[:data]
    |> Map.values()
    |> Enum.filter(fn x -> x==1 end )
    |> length()

  end

  def part_ii(n, filename \\ "lib/Q20/test") do
    {enhancement, image} = read_and_parse(filename)

    #IO.inspect(image[:limits])

    image |> inspect_image()

    enhanced_image =
      0..n-1
      |> Enum.reduce(image,
        fn _i, im ->
          im
          |> enhance(enhancement)
          |> inspect_image()
        end
      ) #|> inspect_image()


    enhanced_image[:data]
    |> Map.values()
    |> Enum.filter(fn x -> x==1 end )
    |> length()
  end
end
