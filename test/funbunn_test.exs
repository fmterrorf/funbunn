defmodule FunbunnTest do
  use ExUnit.Case
  doctest Funbunn

  test "greets the world" do
    assert Funbunn.hello() == :world
  end
end
