defmodule Funbunn.DiscordBody do
  alias Funbunn.Api

  @spec new([Api.reddit_response()]) :: [any()]
  def new(entries) do
    Enum.sort_by(entries, fn item -> item.created_utc end)
    |> Enum.map(&component/1)
    |> Enum.chunk_every(10)
    |> Enum.map(fn embeds -> %{embeds: embeds} end)
  end

  def component(item) do
    %{
      title: item.title,
      url: "https://www.reddit.com" <> item.permalink,
      description: item.selftext,
      author: %{
        name: "u/" <> item.author_name,
        url: "https://www.reddit.com/user/" <> item.author_name
      },
      footer: %{
        text: item.subreddit_name_prefixed
      }
    }
    |> maybe_add_thumbnail(item)
    |> maybe_add_video(item)
    |> maybe_add_image(item)
  end

  defp maybe_add_thumbnail(embed, %{thumbnail: thumbnail} = param)
       when thumbnail not in ["", "self"] do
    Map.put(embed, :thumbnail, %{
      url: thumbnail,
      height: param.thumbnail_height,
      width: param.thumbnail_width
    })
  end

  defp maybe_add_thumbnail(embed, _arg), do: embed

  defp maybe_add_video(embed, %{is_video: true, media: %{"reddit_video" => video}}) do
    Map.update(embed, :description, "", fn description ->
      description <> "\n\n" <> "[Video](#{video["fallback_url"]})"
    end)
  end

  defp maybe_add_video(embed, _arg), do: embed

  defp maybe_add_image(embed, %{url: url}) do
    if String.ends_with?(url, ".jpg") do
      Map.drop(embed, [:thumbnail])
      |> Map.put(:image, %{url: url})
    else
      embed
    end
  end

  defp maybe_add_image(embed, _arg), do: embed
end
