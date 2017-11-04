defmodule Lustex.Errors do
  @moduledoc "lustex exception types"

  defmodule ScriptError do
    @moduledoc "lustex script parse/evaluation error"

    defexception message: nil
  end

  defmodule TemplateError do
    @moduledoc "lustex template parse error"

    defexception message: nil
  end
end
