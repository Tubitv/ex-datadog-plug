defmodule ExDatadogPlugTest do
  use ExUnit.Case, async: false
  use Plug.Test
  import Mock

  alias ExDatadog.Plug.Statix

  test_with_mock "check prefix correctness", Statix, histogram: fn _, _, _ -> :ok end do
    :get
    |> conn("/hello/world")
    |> ExDatadog.Plug.call(prefix: "service")
    |> send_resp(200, "Hello world")

    assert called(Statix.histogram("service.response_time", :_, :_))
  end

  test_with_mock "check method correctness", Statix, histogram: fn _, _, _ -> :ok end do
    :post
    |> conn("/hello/world")
    |> ExDatadog.Plug.call(method: true)
    |> send_resp(200, "Hello world")

    assert called(
             Statix.histogram("plug.response_time", :_,
               tags: ["route:/hello/world", "method:POST"]
             )
           )
  end

  test_with_mock "check query correctness", Statix, histogram: fn _, _, _ -> :ok end do
    :get
    |> conn("/hello/world?bar=10&foo=abcd&args=a,b,1,2")
    |> ExDatadog.Plug.call(method: true, query: ["bar", "args"])
    |> send_resp(200, "Hello world")

    assert called(
             Statix.histogram(
               "plug.response_time",
               :_,
               tags: ["route:/hello/world", "method:GET", "args:a,b,1,2", "bar:10"]
             )
           )
  end

  test_with_mock "check path correctness", Statix, histogram: fn _, _, _ -> :ok end do
    :patch
    |> conn("/?bar=10&foo=abcd&args=a,b,1,2")
    |> ExDatadog.Plug.call(method: true, path: true, prefix: "hello", query: [])
    |> send_resp(200, "Hello world")

    assert called(
             Statix.histogram(
               "hello.response_time",
               :_,
               tags: ["route:/", "path:/", "method:PATCH", "args:a,b,1,2", "bar:10", "foo:abcd"]
             )
           )
  end

  test_with_mock "check static tags correctness", Statix, histogram: fn _, _, _ -> :ok end do
    :patch
    |> conn("/")
    |> ExDatadog.Plug.call(
      method: false,
      path: false,
      prefix: "hello",
      query: [],
      tags: ["version:v1"]
    )
    |> send_resp(200, "Hello world")

    assert called(Statix.histogram("hello.response_time", :_, tags: ["route:/", "version:v1"]))
  end

  test_with_mock "check graphql method extraction", Statix, histogram: fn _, _, _ -> :ok end do
    body = %{
      "operationName" => nil,
      "query" => "mutation {\n  updateUser {\n    code\n    }\n}",
      "variables" => nil
    }

    :post
    |> conn("/graphql", body)
    |> ExDatadog.Plug.call(graphql_method: true)
    |> send_resp(200, "Hello world")

    assert called(
             Statix.histogram("plug.response_time", :_,
               tags: ["route:/graphql", "mutation", "update_user"]
             )
           )
  end

  test_with_mock "check graphql method extraction with query omitted", Statix,
    histogram: fn _, _, _ -> :ok end do
    body = %{
      "operationName" => nil,
      "query" => "{\n  getUser {\n    code\n    }\n}",
      "variables" => nil
    }

    :post
    |> conn("/graphql", body)
    |> ExDatadog.Plug.call(graphql_method: true)
    |> send_resp(200, "Hello world")

    assert called(
             Statix.histogram("plug.response_time", :_,
               tags: ["route:/graphql", "query", "get_user"]
             )
           )
  end
end
