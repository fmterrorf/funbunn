defmodule Funbunn.DiscordBody do
  alias Funbunn.Api
  @icon_url "https://www.redditstatic.com/desktop2x/img/favicon/favicon-32x32.png"

  @spec new([Api.reddit_response()]) :: [any()]
  def new(entries) do
    {gallery, rest} = Enum.split_with(entries, fn item -> item.is_gallery end)

    items =
      Enum.sort_by(rest, fn item -> item.created_utc end)
      |> Enum.map(&component/1)
      |> Enum.chunk_every(10)
      |> Enum.map(fn embeds -> %{embeds: embeds} end)

    gallery_items = Enum.map(gallery, &gallery_message/1)

    items ++ gallery_items
  end

  def gallery_message(item) do
    url = "https://www.reddit.com" <> item.permalink

    title_embed =
      %{
        title: limit_string(item.title, 256),
        url: "https://www.reddit.com" <> item.permalink,
        description: limit_string(item.selftext, 4096),
        footer: %{
          text: item.subreddit_name_prefixed
        }
      }
      |> add_author(item)

    img_embed =
      Enum.to_list(item.media_metadata)
      |> Enum.take(9)
      |> Enum.map(fn {_id, meta} ->
        %{
          url: url,
          image: %{url: meta["s"]["u"]}
        }
      end)

    %{embeds: [title_embed | img_embed]}
  end

  def component(item) do
    %{
      title: limit_string(item.title, 256),
      url: "https://www.reddit.com" <> item.permalink,
      description: limit_string(item.selftext, 4096),
      footer: %{
        text: item.subreddit_name_prefixed
      }
    }
    |> add_author(item)
    |> maybe_add_thumbnail(item)
    |> maybe_add_video(item)
    |> maybe_add_image(item)
  end

  defp maybe_add_thumbnail(embed, %{thumbnail: "http" <> _rest} = param) do
    Map.put(embed, :thumbnail, %{
      url: param.thumbnail,
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

  defp add_author(embed, item) do
    Map.put(embed, :author, %{
      name: "u/" <> item.author_name,
      url: "https://www.reddit.com/user/" <> item.author_name,
      icon_url: @icon_url
    })
  end

  def limit_string(str, length) do
    actual_length = length - 3

    case str do
      <<want::binary-size(actual_length), _::binary>> ->
        "#{want}..."

      str ->
        str
    end
  end
end
