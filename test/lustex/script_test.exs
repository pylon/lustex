defmodule Lustex.ScriptTest do
  use ExUnit.Case, async: true

  import Lustex.Script

  alias Lustex.Errors.ScriptError

  test "types" do
    # lua
    assert eval!("nil", %{}) === nil
    refute eval!("false", %{})
    assert eval!("true", %{})
    assert eval!("1", %{}) === 1
    assert eval!("3.14", %{}) === 3.14
    assert eval!(~S("hello"), %{}) === "hello"
    assert eval!("{}", %{}) === []
    assert eval!("{1}", %{}) === [1]
    assert eval!(~S({"1", 2, 3}), %{}) === ["1", 2, 3]
    assert(eval!("{a=1, b={c=3}}", %{}) === %{"a" => 1, "b" => %{"c" => 3}})

    # erlang
    assert eval!("x", %{}) === nil
    assert eval!("x", %{x: nil}) === nil
    refute eval!("x", %{x: false})
    assert eval!("x", %{x: true})
    assert eval!("x", %{x: 1}) === 1
    assert eval!("x", %{x: 3.14}) === 3.14
    assert eval!("x", %{x: "hello"}) === "hello"
    assert eval!("x", %{x: []}) === []
    assert eval!("x", %{x: [1]}) === [1]
    assert eval!("x", %{x: ["1", 2, 3]}) === ["1", 2, 3]

    assert(
      eval!("x", %{x: %{"a" => 1, "b" => %{"c" => 3}}}) ===
        %{"a" => 1, "b" => %{"c" => 3}}
    )
  end

  test "eval" do
    assert eval("x > 0", %{x: 42}) === {:ok, true}
    assert eval!("x > 0", %{x: 42})

    {:error, %ScriptError{}} = eval("(> x 42)", %{x: 43})

    assert_raise ScriptError, ~r/parse error/, fn ->
      eval!("(> x 42)", %{x: 43})
    end
  end

  test "compile" do
    script = """
    y = 0
    return x >= y and x or -x
    """

    {:ok, compiled} = compile(script)
    assert exec!(compiled, %{x: -42}) == 42

    compiled = compile!(script)
    assert exec!(compiled, %{x: -42}) == 42

    {:error, %ScriptError{}} = compile(~S<}>)

    assert_raise ScriptError, ~r/parse error/, fn ->
      compile!(~S<}>)
    end

    script = "return test"
    {:ok, compiled} = compile(script, globals: %{test: 42})
    assert exec!(compiled, %{}) === 42

    script = "return test()"
    compiled = compile!(script, globals: %{test: callback(fn -> 42 end)})
    assert exec!(compiled, %{}) === 42
  end

  test "exec" do
    script = """
    y = 0
    return x >= y and x or -x
    """

    assert exec(script, %{x: -42}) === {:ok, 42}
    assert exec!(script, %{x: -42}) === 42

    {:error, %ScriptError{}} = exec("invalid", %{})

    assert_raise ScriptError, ~r/parse error/, fn ->
      exec!("invalid", %{})
    end

    {:error, %ScriptError{}} = exec(~S<error("wat")>, %{})

    assert_raise ScriptError, ~r/exec error/, fn ->
      exec!(~S<error("wat")>, %{})
    end
  end

  test "call" do
    script = """
    y = 0
    function abs(x)
      return x >= y and x or -x
    end

    function fail()
      error("wat")
    end
    """

    assert call(script, "abs", [-42]) === {:ok, 42}
    assert call!(script, "abs", [-42]) === 42

    {:error, %ScriptError{}} = call("invalid", "abs", [])

    assert_raise ScriptError, ~r/parse error/, fn ->
      call!("invalid", "abs", [])
    end

    {:error, %ScriptError{}} = call(script, "sgn", [])

    assert_raise ScriptError, ~r/call error/, fn ->
      call!(script, "sgn", [])
    end

    {:error, %ScriptError{}} = call(script, "fail", [])

    assert_raise ScriptError, ~r/call error/, fn ->
      call!(script, "fail", [])
    end
  end

  test "callback" do
    context = %{
      test0: callback(fn -> 0 end),
      test1: callback(fn x, y, z -> [x, y, z] end),
      test2: callback(Lustex.ScriptTest, :inject)
    }

    expect1 = [1, [2, 3], %{"x" => 4}]

    assert eval!("test0()", context) === 0
    assert eval!("test1(1, {2, 3}, {x=4})", context) === expect1
    assert eval!("test2(5)", context) === 5
  end

  test "tostring" do
    assert eval!("tostring({})", %{}) === "[]"
    assert eval!("tostring({{}})", %{}) === "[[]]"
    assert eval!("tostring({1, 2, 3})", %{}) === "[1, 2, 3]"

    expect = inspect(%{"a" => 1, "b" => 2, "c" => 3})
    assert eval!("tostring({a=1, b=2, c=3})", %{}) === expect
  end

  def inject(x) do
    x
  end
end
