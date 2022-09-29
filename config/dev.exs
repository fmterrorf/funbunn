import Config

case System.get_env("STORE", "inmemory") do
  "inmemory" ->
    config :funbunn,
      store: Funbunn.StoreInmemory

  "disk" ->
    config :funbunn,
      store: Funbunn.StoreDisk,
      store_disk_filename:
        System.get_env("STORE_FILENAME", "funbunn_store") |> String.to_charlist()

  "postgres" ->
    config :funbunn,
      store: Funbunn.StorePostgres

    config :funbunn, Funbunn.Repo,
      username: "postgres",
      password: "postgres",
      database: "funbunn_dev",
      hostname: "localhost",
      show_sensitive_data_on_connection_error: true,
      pool_size: 10
end

route_config_string =
  if route_config_path = System.get_env("WEBHOOK_ROUTE_CONFIG_PATH") do
    File.read!(route_config_path)
  else
    "[]"
  end

config :funbunn,
  route_config_string: route_config_string

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"
