defmodule Lustex.TemplateTest do
  use ExUnit.Case, async: true

  import Lustex.Template

  alias Lustex.Script
  alias Lustex.Errors.{ScriptError, TemplateError}

  test "compilation" do
    {:ok, compiled} = compile("test{{value}}")
    assert Script.exec!(compiled, %{value: 1}) == "test1"

    compiled = compile!("test{{value}}")
    assert Script.exec!(compiled, %{value: 1}) == "test1"

    {:error, %TemplateError{}} = compile("{{")
    assert_raise TemplateError, ~r/parse error/, fn ->
      compile!("{{")
    end
  end

  test "rendering" do
    {:ok, rendered} = render("test{{value}}", %{value: 1})
    assert rendered == "test1"

    rendered = render!("test{{value}}", %{value: 1})
    assert rendered == "test1"

    {:error, %TemplateError{}} = render("{{", %{value: 1})
    {:error, %ScriptError{}} = render("{{test.value}}", %{})
    assert_raise TemplateError, ~r/parse error/, fn ->
      render!("{{", %{value: 1})
    end
    assert_raise ScriptError, ~r/exec error/, fn ->
      render!("{{test.value}}", %{})
    end
  end

  test "parse errors" do
    templates = [
      ~S({{ \" }}),
      ~S({{ [  }}),
      ~S({{ ]  }}),
      ~S({{ [[ }}),
      ~S({{ ]] }}),
      ~S({{ {  }}),
      ~S({{ }  }}),
      ~S({{elseif}}1234{{end}}),
      ~S({{else}}1234{{end}}),
    ]
    for template <- templates do
      context = %{}
      assert_raise TemplateError, ~r/parse error/, fn ->
        render!(template, context)
      end
    end
  end

  test "literals" do
    templates = [
      ~S("),
      ~S( "),
      ~S(a"),
      ~S(\""),
      ~S(\\\""),
      ~S(["),
      ~S(]"),
      ~S([["),
      ~S(]]"),
      ~S({"),
      ~S(}"),
      ~S(}}"),
      """
      this is a multi-
      line literal
      """
    ]
    for template <- templates do
      assert render(template, %{value: 1}) === {:ok, template}
    end
  end

  test "expressions" do
    templates = [
      {~S({{value}}), "1"},
      {~S({{ value}}), "1"},
      {~S({{value }}), "1"},
      {~S( {{value}}), " 1"},
      {~S({{value}} ), "1 "},
      {~S({{value}} + {{value}} != {{value + 1}}), "1 + 1 != 2"},
      {~S({{ nil                        }}), ""},
      {~S({{ ""                         }}), ""},
      {~S({{ "\t"                       }}), "\t"},
      {~S({{ "\n"                       }}), "\n"},
      {~S({{ a                          }}), ""},
      {~S({{ 1                          }}), "1"},
      {~S({{ "a"                        }}), "a"},
      {~S({{ value                      }}), "1"},
      {~S({{ value == 0 and 1 or 2      }}), "2"},
      {~S({{ #list                      }}), "3"},
      {~S({{ list[3]                    }}), "3"},
      {~S({{ map.value                  }}), "2"},
      {~S<{{ table.concat(list, ", ")   }}>, "1, 2, 3"},
      {~S({{ "\""           }}), ~S(")},
      {~S({{ "]["           }}), ~S(][)},
      {~S({{ "]][["         }}), ~S(]][[)},
      {~S({{ "}{"           }}), ~S(}{)},
      {~S({{ "}}{{"         }}), ~S(}}{{)},
      {~S({{ "{{do"         }}), ~S({{do)},
      {~S({{ "{{function"   }}), ~S({{function)},
      {~S({{ "{{if"         }}), ~S({{if)},
      {~S({{ "{{elseif"     }}), ~S({{elseif)},
      {~S({{ "{{else}}"     }}), ~S({{else}})},
      {~S({{ "{{for"        }}), ~S({{for)},
      {~S({{ "{{while"      }}), ~S({{while)},
      {~S({{ "{{end}}"      }}), ~S({{end}})},
      {~S({{ [["]]          }}), ~S(")},
      {~S({{ [[}{]]         }}), ~S(}{)},
      {~S({{ [[}}{{]]       }}), ~S(}}{{)},
      {~S({{ [[{{do]]       }}), ~S({{do)},
      {~S({{ [[{{function]] }}), ~S({{function)},
      {~S({{ [[{{if]]       }}), ~S({{if)},
      {~S({{ [[{{elseif]]   }}), ~S({{elseif)},
      {~S({{ [[{{else}}]]   }}), ~S({{else}})},
      {~S({{ [[{{for]]      }}), ~S({{for)},
      {~S({{ [[{{while]]    }}), ~S({{while)},
      {~S({{ [[{{end}}]]    }}), ~S({{end}})},
      {~S({{ do_            }}), ~S(do)},
      {~S({{ function_      }}), ~S(function)},
      {~S({{ if_            }}), ~S(if)},
      {~S({{ elseif_        }}), ~S(elseif)},
      {~S({{ else_          }}), ~S(else)},
      {~S({{ for_           }}), ~S(for)},
      {~S({{ while_         }}), ~S(while)},
      {~S({{ end_           }}), ~S(end)},
    ]
    for {template, result} <- templates do
      context = %{
        value:     1,
        list:      [1, 2, 3],
        map:       %{value: 2},
        do_:       "do",
        function_: "function",
        if_:       "if",
        elseif_:   "elseif",
        else_:     "else",
        for_:      "for",
        while_:    "while",
        end_:      "end",
      }
      assert render(template, context) === {:ok, result}
    end
  end

  test "do" do
    templates = [
      {"{{do x = 1 end}}{{ x }}", "1"},
      {"{{ do x = 2 end}}{{ x }}", "2"},
      {"{{do x = 3 end }}{{ x }}", "3"},
      {"{{ do x = 4 end }}{{ x }}", "4"},
      {"""
       {{
        do
          x = value
          y = 2
        end
       }}{{ x + y }}
       """,
       "3"},
    ]
    for {template, result} <- templates do
      context = %{ value: 1 }
      assert render(template, context) === {:ok, result}
    end
  end

  test "function" do
    templates = [
      {"{{function f() return value end}}{{ f() }}", "1"},
      {"{{ function f(x) return x + 1 end}}{{ f(1) }}", "2"},
      {"{{function f(x) return x + 2 end }}{{ f(1) }}", "3"},
      {"{{ function f(x) return x + 3 end }}{{ f(1) }}", "4"},
      {"""
       {{
        function f(x, y)
          w = {y}
          z = {a=x + w[1]}
          return z.a
        end
       }}{{ f(1, 2) }}
       """,
       "3"},
    ]
    for {template, result} <- templates do
      context = %{ value: 1 }
      assert render(template, context) === {:ok, result}
    end
  end

  test "if" do
    templates = [
      {"{{if false then}}con{{end}}", ""},
      {"{{ if true then}}con{{ end}}", "con"},
      {"{{if value ~= 1 then }}con{{end }}", ""},
      {"{{ if value == 1 then }}con{{ end }}", "con"},
      {
        """
        {{ if false then }}con{{ else }}alt{{ end }}
        """,
        "alt"
      },
      {
        """
        {{ if true then }}con{{ else }}alt{{ end }}
        """,
        "con"
      },
      {
        """
        {{ if false then }}con1{{ elseif false then }}con2{{ end }}
        """,
        ""
      },
      {
        """
        {{ if false then }}con1{{ elseif true then }}con2{{ end }}
        """,
        "con2"
      },
      {
        """
        {{ if true then }}con1{{ elseif false then }}con2{{ end }}
        """,
        "con1"
      },
      {
        """
        {{ if true then }}con1{{ elseif true then }}con2{{ end }}
        """,
        "con1"
      },
      {
        """
        {{
          if false then
            }}con1{{
          elseif false then
            }}con2{{
          elseif false then
            }}con3{{
          end
        }}
        """,
        ""
      },
      {
        """
        {{
          if false then
            }}con1{{
          elseif true then
            }}con2{{
          elseif true then
            }}con3{{
          end
        }}
        """,
        "con2"
      },
      {
        """
        {{
          if false then
            }}con1{{
          elseif false then
            }}con2{{
          elseif true then
            }}con3{{
          end
        }}
        """,
        "con3"
      },
      {
        """
        {{
          if false then
            }}con1{{
          elseif true then
            }}con2{{
          else
            }}alt{{
          end
        }}
        """,
        "con2"
      },
      {
        """
        {{
          if false then
            }}con1{{
          elseif false then
            }}con2{{
          else
            }}alt{{
          end
        }}
        """,
        "alt"
      },
      {
        """
        {{
          if true then
            }}con1{{
            if true then
              }}con2{{
            else
              }}alt1{{
            end
            }}{{
          end
        }}
        """,
        "con1con2"
      },
    ]
    for {template, result} <- templates do
      context = %{ value: 1 }
      assert render(template, context) === {:ok, result}
    end
  end

  test "for" do
    templates = [
      {"{{for k in pairs({0, 1, 2}) do}}{{k}}{{end}}", "123"},
      {"{{ for k in pairs(list) do}}{{k}}{{ end}}", "123"},
      {"{{ for k, v in ipairs(list) do }}{{v}}{{ end }}", "456"},
      {"{{ for i=1, 7, 2 do }}{{i}}{{ end }}", "1357"},
      {
        """
        {{
          for _, x in ipairs(list) do
            }}<{{
            for _, y in ipairs(list) do
              }}[{{
              x .. y
              }}]{{
            end
            }}>{{
          end
        }}
        """,
        "<[44][45][46]><[54][55][56]><[64][65][66]>"
      },
    ]
    for {template, result} <- templates do
      context = %{ list: [4, 5, 6] }
      assert render(template, context) === {:ok, result}
    end
  end

  test "while" do
    templates = [
      {"{{do i = 0 end}}{{while i < 2 do i = i + 1}}{{i}}{{end}}", "12"},
      {"{{ while value > 0 do value = value - 1}}{{value}}{{end}}", "10"},
      {
        """
        {{ do i = 0 end }}
        {{
          while i < 2 do
            i = i + 1
            j = 0
            }}<{{
            while j < 2 do
              j = j + 1
              }}[{{
              i .. j
              }}]{{
            end
            }}>{{
          end
        }}
        """,
        "<[11][12]><[21][22]>"
      },
    ]
    for {template, result} <- templates do
      context = %{ value: 2 }
      assert render(template, context) === {:ok, result}
    end
  end
end
