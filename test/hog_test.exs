defmodule HogTest do
  use ExUnit.Case
  doctest Hog

  test "greets the world" do
    assert Hog.hello() == :world
  end
end
