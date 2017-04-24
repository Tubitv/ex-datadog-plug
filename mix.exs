defmodule ExDatadogPlug.Mixfile do
  use Mix.Project
  @version File.cwd!() |> Path.join("version") |> File.read! |> String.trim

  def project do
    [app: :pre_commit_hook,
     version: @version,
     elixir: "~> 1.4",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:ex_statsd, ">= 0.5.1"},
      {:plug, "~> 1.3.0"},

      # dev & test
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: [:dev, :test]},
      {:mock, "~> 0.2.0", only: :test},
      {:pre_commit_hook, "> 1.0.0", only: [:dev]},
    ]
  end

  defp description do
    """
    ex_datadog_plug helps to collect response time for your plug application.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*", "version"],
      licenses: ["MIT"],
      maintainers: ["tyr.chen@gmail.com"],
      links: %{"GitHub" => "https://github.com/adRise/ex_datadog_plug",
              "Docs" => "http://adrise.github.io/ex_datadog_plug/"},
    ]
  end
end
