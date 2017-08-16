defmodule Slackbot.Zomato do
  @lat "41.3031281"
  @lon "-72.9272339"
  @radius "4828.03"
  @base_url "https://developers.zomato.com/api/v2.1/search?lat=#{@lat}&lon=#{@lon}&radius=#{@radius}&sort=real_distance&order=asc&q="

  @fields ~w(
    name url location
  )

  def restaurant_search(query) do
    user_key = Application.get_env(:slackbot, :user_key)

    response =
      @base_url <> URI.encode(query)
      |> HTTPoison.get!(["X-Zomato-API-Key": user_key])

    %{"restaurants" => restaurants} = Poison.decode!(response.body)

    restaurants
    |> Enum.map(fn(res) -> Map.take(res["restaurant"], @fields) end)
    |> Enum.take(5)
  end

  def format_response(response) do
    num_results = length(response)
    formatted =
      Enum.map(response, fn(res) -> "\n#{res["name"]}\n#{res["url"]}\n#{res["location"]["address"]}\n" end)

      case num_results do
        0 -> "Couldn't find any restaurants that match your search, please try another query"
        _ -> "Here are the closest #{num_results} restaurants that match your query: \n
              #{formatted}"
      end
  end

end
