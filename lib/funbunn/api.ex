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

  @spec fetch_new_entries(binary(), binary()) :: {:ok, [reddit_response()]} | {:error, any()}
  def fetch_new_entries(subbreddit, last_thread_name) do
    json_link(subbreddit, last_thread_name)
    |> Req.get!()
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
          media: data["media"]
        }
      end)

    {:ok, transformed_data}
  end

  defp handle_response(response) do
    {:error, "call to reddit returned with error status #{response.status}"}
  end

  def json_link(subreddit, last_thread_name) do
    url = "#{@host}/r/#{subreddit}/new.json"

    if last_thread_name do
      "#{url}?before=#{last_thread_name}"
    else
      url
    end
  end
end
