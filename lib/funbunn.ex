defmodule Funbunn do
  @moduledoc """
  Documentation for `Funbunn`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Funbunn.hello()
      :world

  """
  def hello do
    :world
  end
end

# data |> xpath(~x"//feed/entry"l, author: ~x"./author/name/text()", link: ~x"./link/@href", title: ~x"./title/text()", thumbnail: ~x"./media:thumbnail/@url")
