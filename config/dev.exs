import Config

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
