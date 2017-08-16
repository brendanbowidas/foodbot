defmodule Slackbot.Favorites do

  def connection do
    {:ok, table} = :dets.open_file(:storage, [type: :set])
    table
  end

  def fetch_favorites do

    [{"favorites", list}] = :dets.lookup(connection, "favorites")
    :dets.close(connection)
    list
  end

  def add_favorite(item) do
    case Enum.member?(fetch_favorites, String.capitalize(item)) do
      true -> {:err, "#{item} is already a favorite"}
      false ->
        new_list = Enum.concat(fetch_favorites, [String.capitalize(item)])
        :dets.insert(connection, {"favorites", new_list})
        {:ok, fetch_favorites}
    end

  end

  def remove_favorite(item) do
    new_list = List.delete(fetch_favorites, item)
    :dets.insert(connection, {"favorites", new_list})
    fetch_favorites
  end

  def clear_favorites do
    :dets.insert(connection, {"favorites", []})
  end

end
