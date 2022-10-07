import Config

if config_env() == :prod do
  route_config_string =
    cond do
      route_config_path = System.get_env("WEBHOOK_ROUTE_CONFIG_BASE64") ->
        Base.decode64!(route_config_path)

      route_config_path = System.get_env("WEBHOOK_ROUTE_CONFIG_PATH") ->
        File.read!(route_config_path)

      true ->
        "[]"
    end

  config :funbunn,
    route_config_string: route_config_string
end
