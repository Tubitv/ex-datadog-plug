defmodule ExDatadogPlug.Mixfile do
  use Mix.Project
  @version File.cwd!() |> Path.join("version") |> File.read!() |> String.trim()

  def project do
    [
      app: :ex_datadog_plug,
      version: @version,
      elixir: "~> 1.4",
      description: description(),
      package: package(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # exdocs
      # Docs
      name: "ExDatadogPlug",
      source_url: "https://github.com/Tubitv/ex_datadog_plug",
      homepage_url: "https://github.com/Tubitv/ex_datadog_plug",
      docs: [
        main: "ExDatadog.Plug",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},
      {:plug, "~> 1.8"},
      {:recase, "~> 0.6"},
      {:statix, "~> 1.2"},

      # dev & test
      {:credo, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.21", only: [:dev, :test]},
      {:mock, "~> 0.3", only: :test},
      {:pre_commit_hook, "~> 1.2", only: [:dev]}
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
      links: %{
        "GitHub" => "https://github.com/Tubitv/ex_datadog_plug",
        "Docs" => "https://hexdocs.pm/ex_datadog_plug"
      }
    ]
  end
end
