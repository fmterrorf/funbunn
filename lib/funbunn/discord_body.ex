defmodule Funbunn.DiscordBody do
  alias Funbunn.Api
  @icon_url "https://www.redditstatic.com/desktop2x/img/favicon/favicon-32x32.png"
  @title_limit 256
  @description_limit 4096

  @spec new([Api.reddit_response()]) :: [any()]
  def new(entries) do
    {gallery, rest} = Enum.split_with(entries, fn item -> item.is_gallery end)

    items =
      Enum.sort_by(rest, fn item -> item.created_utc end)
      |> Enum.map(&embed/1)
      |> Enum.chunk_every(10)
      |> Enum.map(fn embeds -> %{embeds: embeds} end)

    gallery_items = Enum.map(gallery, &gallery_message/1)

    items ++ gallery_items
  end

  def gallery_message(item) do
    title_embed =
      new_embed(item)
      |> add_author(item)
      |> maybe_add_flair(item)
      |> maybe_add_external_link(item)
      |> add_timestamp(item)

    img_embed =
      Enum.to_list(item.media_metadata)
      |> Enum.take(10)
      |> Enum.map(fn {_id, meta} ->
        %{
          url: title_embed.url,
          image: %{url: meta["s"]["u"]}
        }
      end)

    [first_embed | rest_embed] = img_embed

    %{embeds: [Map.merge(title_embed, first_embed) | rest_embed]}
  end

  def embed(item) do
    new_embed(item)
    |> add_timestamp(item)
    |> add_author(item)
    |> maybe_add_thumbnail(item)
    |> maybe_add_video(item)
    |> maybe_add_image(item)
    |> maybe_add_flair(item)
    |> maybe_add_external_link(item)
  end

  def new_embed(item) do
    %{
      title: limit_string(item.title, @title_limit),
      url: "https://www.reddit.com" <> item.permalink,
      description: limit_string(item.selftext, @description_limit),
      fields: [],
      footer: %{
        text: item.subreddit_name_prefixed
      }
    }
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

  defp maybe_add_image(embed, %{post_hint: "image"} = item) do
    do_add_image(embed, item.url)
  end

  defp maybe_add_image(embed, %{post_hint: "link", preview: %{"images" => images}}) do
    [%{"source" => %{"url" => url}} | _] = images
    do_add_image(embed, url)
  end

  defp maybe_add_image(embed, _arg), do: embed

  defp do_add_image(embed, image_url) do
    Map.drop(embed, [:thumbnail])
    |> Map.put(:image, %{url: image_url})
  end

  defp add_timestamp(embed, item) do
    timestamp =
      item.created_at
      |> DateTime.to_iso8601()

    Map.put(embed, :timestamp, timestamp)
  end

  defp add_author(embed, item) do
    Map.put(embed, :author, %{
      name: "u/" <> item.author_name,
      url: "https://www.reddit.com/user/" <> item.author_name,
      icon_url: @icon_url
    })
  end

  defp maybe_add_flair(embed, item) when is_binary(item.link_flair_text) do
    Map.update(embed, :fields, [], fn fields ->
      [
        %{name: "Flair", value: item.link_flair_text, inline: true} | fields
      ]
    end)
  end

  defp maybe_add_flair(embed, _item), do: embed

  defp maybe_add_external_link(embed, %{post_hint: post_hint} = item)
       when post_hint in ["link", "rich:video"] do
    Map.update(embed, :fields, [], fn fields ->
      [
        %{name: "Link", value: item.url, inline: true} | fields
      ]
    end)
  end

  defp maybe_add_external_link(embed, _item), do: embed

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
