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

    assert called ExStatsD.histogram(:_, "plug.response_time", tags: ["/hello/world", "/hello", "POST"])
  end

  test_with_mock "check query correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :get
      |> conn("/hello/world?bar=10&foo=abcd&args=a,b,1,2")
      |> ExDatadog.Plug.call(method: true, query: ["bar", "args"])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "plug.response_time",
      tags: ["/hello/world", "/hello", "GET", "args:a,b,1,2", "bar:10"])
  end

  test_with_mock "check path correctness", ExStatsD, [histogram: fn(_, _, _) -> :ok end] do
    :patch
      |> conn("/?bar=10&foo=abcd&args=a,b,1,2")
      |> ExDatadog.Plug.call(method: true, prefix: "hello", query: [])
      |> send_resp(200, "Hello world")

    assert called ExStatsD.histogram(:_, "hello.response_time",
      tags: ["/", "PATCH", "args:a,b,1,2", "bar:10", "foo:abcd"])
  end
end
