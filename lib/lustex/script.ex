defmodule Lustex.Script do
  @moduledoc """
  lua script execution

  This module provides support for executing custom scripts written in the
  Lua language. These scripts can take on one of the following forms.
  * expression: a simple Lua expression that returns a result from the context
  * chunk: a script block that ends with a return statement
  * function: a script block that defines one or more exported functions

  Expressions can be evaluated using `eval`, chunks can be executed using
  `exec`, and functions can be called using `call`. Eval/exec accept a
  context object that can be used to expose global variables to the script.
  Call accepts a positional parameter list that is passed to the function.

  Scripts can be pre-compiled using the `compile` function. All of the
  execution methods support pre-compiled scripts
  """

  @type compiled::{chunk::any, state::any}

  alias Lustex.Errors.ScriptError

  @doc """
  compiles a Lua script block

  |option   |description                              |default|
  |---------|-----------------------------------------|-------|
  |`globals`|map of global variables to assign        |%{}    |
  |`eval?`  |evaluate the script to initialze globals?|false  |
  """
  @spec compile(script::String.t, options::keyword) ::
    {:ok, compiled} | {:error, any}
  def compile(script, options \\ []) do
    {:ok, compile!(script, options)}
  rescue
    e in ScriptError -> {:error, e}
  end

  @doc """
  compiles a Lua script block, throwing on error
  """
  @spec compile!(script::String.t, options::keyword) :: compiled
  def compile!(script, options \\ []) do
    with {:ok, chunk, state} <- :luerl.load(script) do
      # assign global state
      globals = Map.merge(defaults(), Keyword.get(options, :globals, %{}))
      state = Enum.reduce(globals, state, fn {k, v}, s ->
          :luerl.set_table([k], v, s)
      end)

      # optionally evaluate the script for global state
      if Keyword.get(options, :eval?, false) do
        {_result, state} = :luerl.do(chunk, state)
        {chunk, state}
      else
        {chunk, state}
      end
    else
      {:error, [{line, _type, reason}], _} ->
        raise ScriptError, "parse error on line #{line}: #{inspect(reason)}"
    end
  end

  @doc """
  executes a Lua script within a context and returns an error tuple on
  failure
  """
  @spec exec(script::String.t | compiled, context::map) ::
    {:ok, any} | {:error, any}
  def exec(script, context) do
    {:ok, exec!(script, context)}
  rescue
    e in ScriptError -> {:error, e}
  end

  @doc """
  executes a Lua script within a context and raises on failure
  """
  @spec exec!(script::String.t | compiled, context::map) :: any
  def exec!(script, context) when is_binary(script) do
    script
    |> compile!(eval?: false)
    |> exec!(context)
  end
  def exec!(script, context) do
    {chunk, state} = script
    state = Enum.reduce(
      context,
      state,
      fn {k, v}, a -> :luerl.set_table([k], v, a) end
    )

    {result, _} = :luerl.call_chunk(chunk, [], state)
    lua_to_ex(result)
  rescue
    e in ErlangError -> case e do
      %ErlangError{original: {:lua_error, reason, _}} -> reraise(
        ScriptError,
        "exec error #{inspect(reason)}",
        System.stacktrace
      )
      _ -> reraise(e, System.stacktrace)
    end
  end

  @doc """
  calls a Lua function and returns an error tuple on failure
  """
  @spec call(script::String.t | compiled, function::String.t, [args::any]) ::
    {:ok, any} | {:error, any}
  def call(script, function, args) do
    {:ok, call!(script, function, args)}
  rescue
    e in ScriptError -> {:error, e}
  end

  @doc """
  calls a Lua function and throws on failure
  """
  @spec call!(script::String.t | compiled, function::String.t, [args::any]) ::
    any
  def call!(script, function, args) when is_binary(script) do
    script
    |> compile!(eval?: true)
    |> call!(function, args)
  end
  def call!(script, function, args) do
    {_chunk, state} = script
    {result, _state} = :luerl.call_function([function], args, state)
    lua_to_ex(result)
  rescue
    e in ErlangError -> case e do
      %ErlangError{original: {:lua_error, reason, _}} -> reraise(
          ScriptError,
          "call error (#{function}): #{inspect(reason)}",
          System.stacktrace
      )
      _ -> reraise(e, System.stacktrace)
    end
  end

  @doc """
  generates a Lua-compatible callback for a function
  """
  @spec callback(function::(... -> any)) :: ([any] -> [any])
  def callback(function) do
    fn args ->
      [apply(function, Enum.map(args, &lua_to_ex/1))]
    end
  end

  @doc """
  generates a Lua-compatible callback for a module/function
  """
  @spec callback(module::module, function::(... -> any)) :: ([any] -> [any])
  def callback(module, function) do
    fn args ->
      [apply(module, function, Enum.map(args, &lua_to_ex/1))]
    end
  end

  defp lua_to_ex([{k, _v} | _tail] = table) when is_integer(k) do
    # convert integer-keyed tables to lists
    Enum.map(table, fn {_, v} -> lua_to_ex(v) end)
  end
  defp lua_to_ex([{_k, _v} | _tail] = table) do
    # convert other tables to maps
    table
    |> Enum.map(fn {k, v} -> {k, lua_to_ex(v)} end)
    |> Enum.into(%{})
  end
  defp lua_to_ex([x]) do
    # collapse luerl's extra lists
    lua_to_ex(x)
  end
  defp lua_to_ex(x) when is_float(x) and trunc(x) == x do
    # convert exact floats to ints, since Lua has no integer type
    trunc(x)
  end
  defp lua_to_ex(x) do
    # pass all others
    x
  end

  defp defaults do
    %{
      tostring: callback(&tostring/1),
      print:    callback(&print/1)
    }
  end

  defp tostring(nil), do: ""
  defp tostring(x) when is_binary(x), do: x
  defp tostring(x), do: inspect(x)

  defp print(x) do
    IO.puts(inspect(x))
    nil
  end
end
