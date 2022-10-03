defmodule Funbunn.Api do
  @host "https://reddit.com"

  @type reddit_response :: %{
          name: binary(),
          author_name: binary(),
          link: binary(),
          title: binary(),
          id: binary(),
          thumbnail: binary() | nil,
          thumbnail_height: non_neg_integer() | nil,
          thubnail_width: non_neg_integer() | nil
        }

  @spec fetch_new_entries(binary(), keyword()) :: {:ok, [reddit_response()]} | {:error, any()}
  def fetch_new_entries(subbreddit, opts \\ []) do
    json_link(subbreddit)
    |> Req.get!(params: Keyword.merge(opts, raw_json: 1))
    |> handle_response
  end

  defp handle_response(%{status: 200, body: body}) do
    transformed_data =
      Enum.map(body["data"]["children"], fn %{"data" => data} ->
        %{
          name: data["name"],
          url: data["url"],
          author_name: data["author"],
          created_utc: data["created_utc"],
          permalink: data["permalink"],
          title: data["title"],
          selftext: data["selftext"],
          id: data["name"],
          subreddit_name_prefixed: data["subreddit_name_prefixed"],
          thumbnail: data["thumbnail"],
          thumbnail_height: data["thumbnail_height"],
          thumbnail_width: data["thumbnail_width"],
          is_video: data["is_video"],
          media: data["media"],
          is_gallery: data["is_gallery"],
          media_metadata: data["media_metadata"],
          link_flair_text: data["link_flair_text"],
          post_hint: data["post_hint"]
        }
      end)

    {:ok, transformed_data}
  end

  defp handle_response(response) do
    {:error, "call to reddit returned with error status #{response.status}"}
  end

  def json_link(subreddit) do
    "#{@host}/r/#{subreddit}/new.json"
  end
end
