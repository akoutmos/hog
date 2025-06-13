defmodule Hog.MixProject do
  use Mix.Project

  def project do
    [
      app: :hog,
      version: project_version(),
      elixir: "~> 1.17",
      name: "Hog",
      source_url: "https://github.com/akoutmos/hog",
      homepage_url: "https://hex.pm/packages/hog",
      description: "Pinpoint and deal with memory hungry processes.",
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "hog",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md VERSION),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/hog",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.png",
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_options, "~> 1.1"},
      {:telemetry, "~> 1.3"},

      # Development deps
      {:ex_doc, "~> 0.38", only: :dev},
      {:doctor, "~> 0.22", only: :dev},
      {:credo, "~> 1.7", only: :dev}
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp project_version do
    "VERSION"
    |> File.read!()
    |> String.trim()
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
