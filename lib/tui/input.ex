defmodule ExStorage.TUI.Input do
  @spec read_event() :: atom() | {:char, String.t()} | :eof | {:ctrl_c}
  def read_event do
    case IO.getn("", 1) do
      :eof ->
        :eof

      <<3>> ->
        {:ctrl_c}

      "\e" ->
        handle_escape(IO.getn("", 2))

      "\r" ->
        :enter

      "\n" ->
        :enter

      "q" ->
        :quit

      <<char>> when char in ?a..?z or char in ?A..?Z ->
        {:char, <<char>>}

      other ->
        {:char, other}
    end
  end

  defp handle_escape("[A"), do: :up
  defp handle_escape("[B"), do: :down
  defp handle_escape("[C"), do: :right
  defp handle_escape("[D"), do: :left
  defp handle_escape(_), do: :unknown
end
