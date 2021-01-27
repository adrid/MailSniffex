import Config

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    "z/5V7XgbaHsezI1e8NRHWOkL4Rhde6rLA4JBPtLNh13Bic26QM4dIsOhXvqiVLDv"

config :mail_sniffex,
  smtp_opts: [{:port, System.get_env("SMTP_PORT") || 2525}],
  size_limit: System.get_env("SIZE_LIMIT") || "1GB"

config :mail_sniffex, MailSniffexWeb.Endpoint,
  url: [
    host: System.get_env("HOST_URL") || "localhost",
    port: System.get_env("HOST_PORT") || System.get_env("PORT") || "4000",
    scheme: System.get_env("HOST_SCHEME") || "http"
  ],
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  server: true
