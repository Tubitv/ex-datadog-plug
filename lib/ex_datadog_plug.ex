defmodule ExDatadog.Plug do
  @moduledoc """
  A plug for logging response time in datadog. To use it, just plug it into the desired module.

      plug ExDatadog.Plug, prefix: "your-service", method: true, query: []

  ## Options

    * `:prefix` - the prefix you want to put for this stat.
      Default is `plug`.
    * `:method` - a boolean value to include the method in the tag list.
      Default is `false`.
    * `:query` - a list of strings to include specific query string in the tag list. `[]` will generate all query
      params as tags.
      Default is `nil` (do not generate tag for query string)
  """

  alias Plug.Conn
  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    prefix = Keyword.get(opts, :prefix, "plug")
    start = System.monotonic_time()

    Conn.register_before_send(conn, fn conn ->
      stop = System.monotonic_time()
      diff = System.convert_time_unit(stop - start, :native, :milli_seconds)

      ExStatsD.histogram(diff, prefix <> ".response_time",  tags: gen_tags(conn, opts))
      conn
    end)
  end

  defp gen_tags(conn, opts) do
    include_method? = Keyword.get(opts, :method, false)
    query_list = Keyword.get(opts, :query, nil)

    conn.request_path
      |> gen_path_tags
      |> Enum.concat(gen_method_tags(conn.method, include_method?))
      |> Enum.concat(gen_query_tags(conn.query_string, query_list))
  end

  defp gen_path_tags("/"), do: ["/"]

  defp gen_path_tags(path) do
    path = Regex.replace(~r/\/$/, path, "")
    [path, Path.dirname(path)]
  end

  defp gen_method_tags(_method, false), do: []
  defp gen_method_tags(method, true), do: [method]

  defp gen_query_tags(_query_string, nil), do: []
  defp gen_query_tags(query_string, query_list) do
    query = query_string
      |> Plug.Conn.Query.decode
      |> Enum.map(fn {k, v} -> {k, "#{k}:#{v}"} end)
      |> Enum.into(%{})

    case query_list do
      []    -> Map.values(query)
      _     -> Enum.filter_map(query, fn {k, _} -> k in query_list end, fn {_, v} -> v end)
    end

  end
end
