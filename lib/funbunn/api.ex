defmodule Funbunn.Api do
  import SweetXml
  @host "https://reddit.com"

  def send_to_discord(_items) do
    # IO.inspect("send_to_discord is sending #{length(items)} items")
  end

  def fetch_new_entries(subbreddit) do
    rss_link(subbreddit)
    |> Req.get!()
    |> handle_response
  end

  defp handle_response(%{status: 200} = response) do
    transformed_data =
      response.body
      |> xpath(~x"//feed/entry"l,
        author: ~x"./author/name/text()",
        link: ~x"./link/@href",
        title: ~x"./title/text()",
        id: ~x"./id/text()",
        thumbnail: ~x"./media:thumbnail/@url"
      )

    {:ok, transformed_data}
  end

  defp handle_response(response) do
    {:error, "call to reddit returned with error status #{response.status}"}
  end

  defp rss_link(subreddit) do
    "#{@host}/r/#{subreddit}/.rss"
  end
end
