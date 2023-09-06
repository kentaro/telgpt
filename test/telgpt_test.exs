defmodule TelgptTest do
  use ExUnit.Case
  doctest Telgpt

  test "greets the world" do
    assert Telgpt.hello() == :world
  end
end
