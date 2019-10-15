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
    * `:statix_module` - a module value
  """

  alias ExDatadog.Plug.Statix

  alias Plug.Conn
  alias Plug.Conn.Query

  @behaviour Plug

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    prefix = Keyword.get(opts, :prefix, "plug")
    start = System.monotonic_time()
    module = Keyword.get(opts, :statix_module, Statix)

    Conn.register_before_send(conn, fn conn ->
      stop = System.monotonic_time()
      diff = System.convert_time_unit(stop - start, :native, :millisecond)

      module.histogram(prefix <> ".response_time", diff, tags: gen_tags(conn, opts))
      conn
    end)
  end

  @doc false
  defp gen_tags(conn, opts) do
    include_method? = Keyword.get(opts, :method, false)
    include_path? = Keyword.get(opts, :path, false)
    query_list = Keyword.get(opts, :query, nil)
    static_tags = Keyword.get(opts, :tags, [])

    conn.path_info
    |> gen_route_tags(conn.path_params)
    |> Enum.concat(gen_path_tags(conn.path_info, include_path?))
    |> Enum.concat(gen_method_tags(conn.method, include_method?))
    |> Enum.concat(gen_query_tags(conn.query_string, query_list))
    |> Enum.concat(static_tags)
  end

  @doc false
  defp gen_route_tags(path_info, path_params) when path_params == %{},
    do: [join_path(path_info, "route")]

  defp gen_route_tags(path_info, path_params) do
    reversed_params = Enum.reduce(path_params, %{}, fn {k, v}, acc -> Map.put(acc, v, k) end)

    path_info
    |> Enum.map(fn v -> Map.get(reversed_params, v) || v end)
    |> gen_route_tags(%{})
  end

  @doc false
  defp gen_path_tags(_path_info, false), do: []
  defp gen_path_tags(path_info, true), do: [join_path(path_info, "path")]

  @doc false
  defp gen_method_tags(_method, false), do: []
  defp gen_method_tags(method, true), do: [method]

  @doc false
  defp gen_query_tags(_query_string, nil), do: []

  defp gen_query_tags(query_string, query_list) do
    query =
      query_string
      |> Query.decode()
      |> Enum.map(fn {k, v} -> {k, "#{k}:#{v}"} end)
      |> Enum.into(%{})

    case query_list do
      [] -> Map.values(query)
      _ -> query |> Enum.filter(fn {k, _} -> k in query_list end) |> Enum.map(fn {_, v} -> v end)
    end
  end

  @doc false
  defp join_path(path_info, prefix), do: "#{prefix}:/#{Enum.join(path_info, "/")}"
end
