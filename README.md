# Lustex

Lua-based string templates for Elixir

The API reference is available [here](https://hexdocs.pm/lustex/).

## Installation

```elixir
def deps do
  [
    {:lustex, "~> 0.1.0"}
  ]
end
```

## Usage

### Basics
Lustex templates use `{{` and `}}` as code delimiters. A code block may
contain any valid Lua expression or statement. These code blocks are
evaluated using the excellent [luerl](https://github.com/rvirding/luerl)
library.

```elixir
template = """
The answer: {{answer}}.
"""

Lustex.Template.render!(template, %{"answer" => 42})
```

```
>> The answer: 42.
```

### Expressions
Expression blocks are simple Lua expressions, which return a single value that
can be converted to a string representation. These are essentially Lua chunks
wrapped in a `return` statement.

```elixir
template = """
I have {{ value % 2 == 0 and 3 or 4 }} {{ fruit }}.
"""

Lustex.Template.render!(template, %{value: 3, fruit: "pears"})
```

```
>> I have 4 pears.
```

### Blocks and Functions
Lua code blocks and functions can be embedded directly in a template and
later referred to in an expression or any other block.

```elixir
template = """
{{
  do
    parsecs = 12
  end
}}
{{
  function speed(x)
    return x + parsecs
  end
}}
It's the ship that made the Kessel Run in less than {{ speed(x) }} parsecs.
"""

Lustex.Template.render!(template, %{x: 2})
```

```
>> It's the ship that made the Kessel Run in less than 14 parsecs.
```

Of course, because these blocks are just Lua code, you can simply combine
the `do` and `function` statements above into a single block.

### Conditional Statements
Similarly, Lustex supports the `if`/`else`/`elseif`/`end` conditional
statements from Lua. The body of each clause is a nested template.

```elixir
template = """
Where we're going, we {{
  if roads then
    }}do {{ want }}{{
  else
    }}don't {{ want }}{{
  end
}} roads.
"""

Lustex.Template.render!(template, %{roads: false, want: "need"})
```

```
>> Where we're going, we don't need roads.
```

### Loops
Lua's `for` and `while` loops are also supported. Loop bodies are nested
Lustex templates.

```elixir
template = """
Do you believe in {{
  for i, v in pairs(beliefs) do }}{{
    if i < #beliefs then
      }}{{ v }}, {{
    else
      }}and {{ v }}{{
    end }}{{
  end
}}?
"""

beliefs = [
  "UFOs",
  "astral projections",
  "mental telepathy",
  "ESP",
  "clairvoyance",
  "spirit photography",
  "telekinetic movement",
  "full-trance mediums",
  "the Loch Ness Monster",
  "the Theory of Atlantis"
]
Lustex.Template.render!(template, %{beliefs: beliefs})
```

```
>> Do you believe in UFOs, astral projections, mental telepathy, ESP,
clairvoyance, spirit photography, telekinetic movement, full-trance mediums,
the Loch Ness Monster, and the Theory of Atlantis?
```

### Compilation
Templates can also be pre-compiled. Doing so parses the Lua script that
represents the template. This is useful for caching frequently used templates
for more efficient rendering. Compiled templates can then be executed using
one of the `render` functions.

```elixir
template = """
I've got {{ number }} people down here, and they're covered with {{ material }}.
"""

compiled = Lustex.Template.compile!(template)
Lustex.Template.render!(compiled, %{number: 100, material: "glass"})
```

```
>> I've got 100 people down here, and they're covered with glass.
```


## License

Copyright 2017 Pylon, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
