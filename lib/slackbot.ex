defmodule Slackbot do
  use Slack
  use Application

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do

    if Map.has_key?(message, :text) do

      cond do
        # @foodbot help
        String.contains?(message.text, "<@#{slack.me.id}> help") ->
          msg = ~s(
          Hello, I am foodbot. Here is a list of my commands:
          \n*@foodbot find <type of food>*:  I will give you a list of restaurants matching the type of food you're looking for \(I personally recommend "Air Sandwiches" 👌\).
          \n*@foodbot show favorites*: I will show you your current list of favorite restaurants you have saved with me.
          \n*@foodbot add favorite <name of restaurant>*: I will add a restaurant to your team's "favorites" list.
          \n*@foodbot remove favorite <name of restaurant>*: I will remove a restaurant from your team's "favorites" list.
          \n*@foodbot decide*: Can't decide where to go? I will pick a restaurant at random from your team's "favorites" list.
          \n*@foodbot decide from <list of restaurants>*: Same as decide, but I will choose from the list of restaurants you provide \(separated by spaces or commas\)
          )

          send_message(msg, message.channel, slack)


        # @foodbot find
        String.contains?(message.text, "<@#{slack.me.id}> find") ->
          extract_query(message.text, "find")
          |> Slackbot.Zomato.restaurant_search
          |> Slackbot.Zomato.format_response
          |> send_message(message.channel, slack)

        # @foodbot show favorites
        String.contains?(message.text, "<@#{slack.me.id}> show favorites") ->
          post_favorites
          |> send_message(message.channel, slack)

        # @foodbot add favorite
        String.contains?(message.text, "<@#{slack.me.id}> add favorite") ->
          new_favorite = extract_query(message.text, "favorite")

          case Slackbot.Favorites.add_favorite(new_favorite)  do
            {:ok, _favorites} -> send_message("#{new_favorite} has been added to favorites.", message.channel, slack)
            {:err, error_message} -> send_message(error_message, message.channel, slack)
          end

        # @foodbot remove favorite
        String.contains?(message.text, "<@#{slack.me.id}> remove favorite") ->
          to_remove = extract_query(message.text, "favorite")
          Slackbot.Favorites.remove_favorite(to_remove)
          send_message("#{to_remove} has been removed from favorites.", message.channel, slack)

        # @foodbot clear favorites
        String.contains?(message.text, "<@#{slack.me.id}> clear favorites") ->
          Slackbot.Favorites.clear_favorites
          send_message("All favorites have been removed.", message.channel, slack)

        # @foodbot decide from
        String.contains?(message.text, "<@#{slack.me.id}> decide from") ->
          places = extract_query(message.text, "from")
                   |> String.split([" ", ","])
                   |> Enum.filter(fn(el) -> el != "" end)
          send_message("Let's go to #{decision_from(places)}", message.channel, slack)

        # @foodbot decide
        String.contains?(message.text, "<@#{slack.me.id}> decide") ->
           send_message("Let's go to #{decision}!", message.channel, slack)


        true -> {:ok, state}
      end

      {:ok, state}
    else
      {:ok, state}
    end

  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message"

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}

  def start(_type, _args) do
    slack_token = Application.get_env(:slackbot, :token)
    Slack.Bot.start_link(Slackbot, [], slack_token, %{keepalive: 30000})
  end

  def extract_query(message, splitter) do
    String.split(message, splitter)
    |> List.last
    |> String.trim
  end

  def post_favorites do
    case Slackbot.Favorites.fetch_favorites do
      "There are no favorites" -> "There are no favorites"
      list -> Enum.map_join(list, "\n", &(&1))
    end
  end

  def decision do
    Slackbot.Favorites.fetch_favorites
    |> Enum.random
  end

  def decision_from(places) do
    places
    |> Enum.random
  end

end
