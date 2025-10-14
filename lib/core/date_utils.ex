defmodule ExStorage.Core.DateUtils do

  def date_pattern, do: "yyyy-mm-dd hh:mm:ss"

  def to_millis(str) do
    str = String.trim(str)
    try do
      cond do
        Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, str) ->
          with {:ok, date} <- Date.from_iso8601(str),
               {:ok, ndt} <- NaiveDateTime.new(date, ~T[00:00:00]) do
            ndt
            |> DateTime.from_naive!("Etc/UTC")
            |> DateTime.to_unix(:millisecond)
          end

        Regex.match?(~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, str) ->
          iso = String.replace(str, " ", "T")

          NaiveDateTime.from_iso8601!(iso)
          |> DateTime.from_naive!("Etc/UTC")
          |> DateTime.to_unix(:millisecond)

        true ->
          {:ok, dt, _} = DateTime.from_iso8601(str)
          DateTime.to_unix(dt, :millisecond)
      end
    rescue
      err ->
        Log.error("An error occurred while formatting the date. Actual value: #{str}", err)

        0
    end
  end

  def from_millis(nil)  do
    ""
  end

  def from_millis(ms) when is_integer(ms) do
    ms
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_iso8601()
    |> String.replace("T", " ")
    |> String.replace("Z", "")
  end
end
