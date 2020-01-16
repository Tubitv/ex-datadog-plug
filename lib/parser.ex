defmodule ExDatadog.QueryParser do
  import NimbleParsec

  # a simple parse try to match ["mutation", "updateUser"] for query: "mutation {\n  updateUser {\n    code\n    hash\n  }\n}"
  space = ascii_string([?\s, ?\t, ?\n], min: 1) |> repeat()
  bracket = string("{")
  tag = ascii_string([?a..?z, ?A..?Z], min: 1)

  query =
    choice([tag, string("")])
    |> ignore(space)
    |> ignore(bracket)
    |> ignore(space)
    |> concat(tag)
    |> ignore(space)
    |> ignore(bracket)

  defparsec(:parse, query)
end
