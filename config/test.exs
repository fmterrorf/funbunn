import Config

config :funbunn, LiveBeats.Repo,
  username: "postgres",
  password: "postgres",
  database: "funbunn_test",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Print only warnings and errors during test
config :logger, level: :warn
