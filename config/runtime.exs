import Config

if config_env() == :prod do
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
      database_url =
        System.get_env("DATABASE_URL") ||
          raise """
          environment variable DATABASE_URL is missing.
          For example: ecto://USER:PASS@HOST/DATABASE
          """

      ecto_ipv6? = System.get_env("ECTO_IPV6") == "true"

      config :funbunn, Funbunn.Repo,
        # ssl: true,
        socket_options: if(ecto_ipv6?, do: [:inet6], else: []),
        url: database_url,
        pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

      config :funbunn,
        store: Funbunn.StorePostgres
  end

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
