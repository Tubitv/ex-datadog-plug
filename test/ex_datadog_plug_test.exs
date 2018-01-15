defmodule ExDatadogPlugTest do
  use ExUnit.Case, async: false
  use Plug.Test
  import Mock

  test_with_mock "check prefix correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :get
      |> conn("/hello/world")
      |> ExDatadog.Plug.call([prefix: "service"])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "service.response_time",  :_)
  end

  test_with_mock "check method correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :post
      |> conn("/hello/world")
      |> ExDatadog.Plug.call([method: true])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "plug.response_time", tags: ["route:/hello/world", "POST"])
  end

  test_with_mock "check query correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :get
      |> conn("/hello/world?bar=10&foo=abcd&args=a,b,1,2")
      |> ExDatadog.Plug.call(method: true, query: ["bar", "args"])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "plug.response_time",
      tags: ["route:/hello/world", "GET", "args:a,b,1,2", "bar:10"])
  end

  test_with_mock "check path correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :patch
      |> conn("/?bar=10&foo=abcd&args=a,b,1,2")
      |> ExDatadog.Plug.call(method: true, path: true, prefix: "hello", query: [])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "hello.response_time",
      tags: ["route:/", "path:/", "PATCH", "args:a,b,1,2", "bar:10", "foo:abcd"])
  end

  test_with_mock "check static tags correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :patch
      |> conn("/")
      |> ExDatadog.Plug.call(method: false, path: false, prefix: "hello", query: [], tags: ["version:v1"])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "hello.response_time",
      tags: ["route:/", "version:v1"])
  end
end
