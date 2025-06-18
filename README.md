<p align="center">
  <img align="center" width="25%" src="guides/images/logo.png" alt="Hog Logo">
</p>

<p align="center">
  Pinpoint and deal with memory hungry processes
</p>

<p align="center">
  <a href="https://hex.pm/packages/hog">
    <img alt="Hex.pm" src="https://img.shields.io/hexpm/v/hog?style=for-the-badge">
  </a>

  <a href="https://github.com/akoutmos/hog/actions">
    <img alt="GitHub Workflow Status (master)"
    src="https://img.shields.io/github/actions/workflow/status/akoutmos/hog/main.yml?label=Build%20Status&style=for-the-badge&branch=master">
  </a>

  <a href="https://coveralls.io/github/akoutmos/hog?branch=master">
    <img alt="Coveralls master branch" src="https://img.shields.io/coveralls/github/akoutmos/hog/master?style=for-the-badge">
  </a>

  <a href="https://github.com/sponsors/akoutmos">
    <img alt="Support the project" src="https://img.shields.io/badge/Support%20the%20project-%E2%9D%A4-lightblue?style=for-the-badge">
  </a>
</p>

<br>

# Contents

- [Installation](#installation)
- [Supporting Hog](#supporting-hog)
- [Using Hog](#setting-up-hog)

## Installation

[Available in Hex](https://hex.pm/packages/hog), the package can be installed by adding `hog` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hog, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/hog](https://hexdocs.pm/hog).

## Supporting Hog

If you rely on this library, it would much appreciated if you can give back to the project
in order to help ensure its continued development.

Checkout my [GitHub Sponsorship page](https://github.com/sponsors/akoutmos) if you want to help out!

### Gold Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58083">
  <img align="center" height="175" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Silver Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58082">
  <img align="center" height="150" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Bronze Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=17615">
  <img align="center" height="125" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

## Using Hog

Add `{:hog, "~> 0.1.0"}` to your `mix.exs` file and run `mix deps.get`. After installing the dependency,
you can add the following line to your `application.ex` file:

```elixir
defmodule MyApp.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # If the defaults laid out in `Hog` work for your use case, you can have
      # just `Hog`, else provide your specific options.
      {Hog, scan_interval: {30, :seconds}, memory_threshold: {100, :megabytes}},
      ...
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ...
end
```

With that in place, you can start your application and memory hungry processes will be logged using the `Logger`
module. If the default logging function does not provide adequate information to help track down the memory hungry
process, you can always provide your own `:event_handler` to the `Hog` GenServer via config or even tie into the
`:telemetry` events yourself using the `Hog.TelemetryEvents` module.
