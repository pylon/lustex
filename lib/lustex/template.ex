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

  For options, see Lustex.Script.compile.
  """
  @spec render(
          template :: String.t() | Script.compiled(),
          context :: map,
          options :: keyword
        ) :: {:ok, String.t()} | {:error, any}
  def render(template, context, options \\ []) do
    {:ok, render!(template, context, options)}
  rescue
    e in [ScriptError, TemplateError] -> {:error, e}
  end

  @doc """
  renders a string or compiled template, throwing on error
  """
  @spec render!(
          template :: String.t() | Script.compiled(),
          context :: map,
          options :: keyword
        ) :: String.t()
  def render!(template, context, options \\ [])

  def render!(template, context, options) when is_binary(template) do
    template
    |> compile!(options)
    |> render!(context)
  end

  def render!(template, context, _options) do
    Script.exec!(template, context)
  end

  @doc """
  compiles a string template to a Lua chunk for later evaluation
  """
  @spec compile(template :: String.t(), options :: keyword) ::
          {:ok, Script.compiled()} | {:error, any}
  def compile(template, options \\ []) do
    {:ok, compile!(template, options)}
  rescue
    e in [ScriptError, TemplateError] -> {:error, e}
  end

  @doc """
  compiles a string template, throwing on error
  """
  @spec compile!(template :: String.t(), options :: keyword) ::
          Script.compiled()
  def compile!(template, options \\ []) do
    template
    |> lex!()
    |> parse!()
    |> Script.compile!(options)
  end

  defp lex!(template) do
    case :lustex_lexer.string(to_charlist(template)) do
      {:ok, tokens, _line} ->
        tokens

      {:error, reason, _line} ->
        raise TemplateError, "parse error, #{inspect(reason)}"
    end
  end

  defp parse!(tokens) do
    case :lustex_parser.parse(tokens) do
      {:ok, script} ->
        script

      {:error, reason} ->
        raise TemplateError, "parse error: #{inspect(reason)}"
    end
  end
end
