defmodule ExDatadog.Plug do
  @moduledoc """
  A plug for logging response time in datadog. To use it, just plug it into the desired module.

      plug ExDatadog.Plug, prefix: "your-service", method: true, query: []

  ## Options

    * `:prefix` - the prefix you want to put for this stat.
      Default is `plug`.
    * `:method` - a boolean value to include the method in the tag list.
      Default is `false`.
    * `:path` - a boolean value to include the path in the tag list.
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
    include_path? = Keyword.get(opts, :path, false)
    query_list = Keyword.get(opts, :query, nil)

    conn.path_info
      |> gen_route_tags(conn.path_params)
      |> Enum.concat(gen_path_tags(conn.path_info, include_path?))
      |> Enum.concat(gen_method_tags(conn.method, include_method?))
      |> Enum.concat(gen_query_tags(conn.query_string, query_list))
  end

  defp gen_route_tags(path_info, path_params) when map_size(path_params) == 0, do: [join_path(path_info, "route")]
  defp gen_route_tags(path_info, path_params) do
    reversed_params = Enum.reduce(path_params, %{}, fn {k, v}, acc -> Map.put(acc, v, k) end)
    path_info
      |> Enum.map(fn v -> Map.get(reversed_params, v) || v end)
      |> gen_route_tags(%{})
  end

  defp gen_path_tags(_path_info, false), do: []
  defp gen_path_tags(path_info, true), do: [join_path(path_info, "path")]

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

  defp join_path(path_info, prefix), do: "#{prefix}:/#{Enum.join(path_info, "/")}"
end
