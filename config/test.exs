use Mix.Config

config :mail_sniffex,
  allowed_headers: ["To", "From", "Subject", "Test-ID"],
  data_path: System.get_env("DATA_DIR_PATH") || Path.join(System.tmp_dir!(), "mail_sniffex_tmp")

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mail_sniffex, MailSniffexWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
