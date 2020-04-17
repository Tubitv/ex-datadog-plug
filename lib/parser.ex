defmodule ExDatadog.QueryParser do
  @moduledoc false

  import NimbleParsec

  # a simple parse try to match ["mutation", "updateUser"] for query: "mutation {\n  updateUser {\n    code\n    hash\n  }\n}"
  space =
    [?\s, ?\t, ?\n]
    |> ascii_string(min: 1)
    |> repeat()

  bracket = string("{")
  tag = ascii_string([?a..?z, ?A..?Z], min: 1)

  query =
    [tag, string("")]
    |> choice()
    |> ignore(space)
    |> ignore(bracket)
    |> ignore(space)
    |> concat(tag)
    |> ignore(space)
    |> ignore(bracket)

  defparsec(:parse, query)
end
