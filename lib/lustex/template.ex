defmodule Lustex.Template do
  @moduledoc """
  lua template rendering

  The rendering module supports compiling and evaluating Lua-based string
  templates. Templates are compiled to a Lua script block and then evaluated
  within the specified context. Template strings may also be evaluated
  directly.
  """

  alias Lustex.Script
  alias Lustex.Errors.{ScriptError, TemplateError}

  @doc """
  renders a string or compiled template within the specified context map
  """
  @spec render(template::String.t | Script.compiled, context::map) ::
    {:ok, String.t} | {:error, any}
  def render(template, context) do
    {:ok, render!(template, context)}
  rescue
    e in [ScriptError, TemplateError] -> {:error, e}
  end

  @doc """
  renders a string or compiled template, throwing on error
  """
  @spec render!(template::String.t | Script.compiled, context::map) :: String.t
  def render!(template, context) when is_binary(template) do
    template
    |> compile!()
    |> render!(context)
  end
  def render!(template, context) do
    Script.exec!(template, context)
  end

  @doc """
  compiles a string template to a Lua chunk for later evaluation
  """
  @spec compile(template::String.t) ::
    {:ok, Script.compiled} | {:error, any}
  def compile(template) do
    {:ok, compile!(template)}
  rescue
    e in [ScriptError, TemplateError] -> {:error, e}
  end

  @doc """
  compiles a string template, throwing on error
  """
  @spec compile!(template::String.t) :: Script.compiled
  def compile!(template) do
    template
    |> lex!()
    |> parse!()
    |> Script.compile!()
  end

  defp lex!(template) do
    case :lustex_lexer.string(to_charlist(template)) do
      {:ok, tokens, _line} -> tokens
      {:error, reason, _line} ->
        raise TemplateError, "parse error, #{inspect(reason)}"
    end
  end

  defp parse!(tokens) do
    case :lustex_parser.parse(tokens) do
      {:ok, script} -> script
      {:error, reason} ->
        raise TemplateError, "parse error: #{inspect(reason)}"
    end
  end
end
