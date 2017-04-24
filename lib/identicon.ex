defmodule Identicon do
  @moduledoc"""
    Will produce an Image, similar to GitHubs generic profile image
    for new accounts, based on the String input given.
  """

  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Returns an Identicon.Image struct with an md5 hash of the given a String argument stored at the property named: `hex`.

  ## Examples
      iex> Identicon.hash_input('hoyups')
      %Identicon.Image{color: nil, grid: nil,
      hex: [58, 80, 136, 92, 134, 191, 78, 25, 5, 220, 245, 240, 83, 82, 0, 40],
      pixel_map: nil}
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list
    %Identicon.Image{hex: hex}
  end

  @doc """
    Saves to Identicon.Image structs as `color`

    Copies first three values to be used as the main color within the image.

  ## Examples
      iex> image = Identicon.hash_input('hoyups')
      iex> Identicon.pick_color(image)
      %Identicon.Image{color: {58, 80, 136}, grid: nil,
      hex: [58, 80, 136, 92, 134, 191, 78, 25, 5, 220, 245, 240, 83, 82, 0, 40],
      pixel_map: nil}
  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  @doc """
    Saves to Identicon.Image structs as `grid`

  ## Example
      iex> image = Identicon.hash_input('hoyups')
      iex> Identicon.build_grid(image)
      %Identicon.Image{color: nil,
      grid: [{58, 0}, {80, 1}, {136, 2}, {80, 3}, {58, 4}, {92, 5}, {134, 6},
      {191, 7}, {134, 8}, {92, 9}, {78, 10}, {25, 11}, {5, 12}, {25, 13}, {78, 14},
      {220, 15}, {245, 16}, {240, 17}, {245, 18}, {220, 19}, {83, 20}, {82, 21},
      {0, 22}, {82, 23}, {83, 24}],
      hex: [58, 80, 136, 92, 134, 191, 78, 25, 5, 220, 245, 240, 83, 82, 0, 40],
      pixel_map: nil}
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  def mirror_row(row) do
    [first, second | _tail] = row

    row ++ [second, first]
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50

      top_left = {horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end
end
