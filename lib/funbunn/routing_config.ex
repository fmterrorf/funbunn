defmodule Funbunn.RoutingConfig do
  @type t :: %__MODULE__{webhook: binary(), subreddit: binary()}

  defstruct webhook: nil, subreddit: nil

  def parse!(config) do
    Jason.decode!(config)
    |> Enum.map(fn item ->
      %__MODULE__{
        webhook: item["webhook"],
        subreddit: item["subreddit"]
      }
    end)
  end
end
