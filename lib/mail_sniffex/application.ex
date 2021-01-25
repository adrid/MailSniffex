defmodule MailSniffex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MailSniffexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MailSniffex.PubSub},
      # Start the Endpoint (http/https)
      MailSniffexWeb.Endpoint,
      # Start a worker by calling: MailSniffex.Worker.start_link(arg)
      # {MailSniffex.Worker, arg},
      %{
        id: :gen_smtp_server,
        start:
          {:gen_smtp_server, :start,
           [MailSniffex.Server, [Application.get_env(:mail_sniffex, :smtp_opts)]]}
      },
      MailSniffex.DB,
      MailSniffex.SizeWatcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MailSniffex.Supervisor]

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MailSniffexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
