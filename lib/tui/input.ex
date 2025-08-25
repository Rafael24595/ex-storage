defmodule ExStorage.TUI.Input do
  @spec read_event() :: atom() | {:char, String.t()} | :eof | {:ctrl_c}
  def read_event do
    IO.gets("")
    |> normalize()
  end

  defp normalize(:eof), do: :eof
  defp normalize(<<3>>), do: {:ctrl_c}
  defp normalize("\n"), do: :enter
  defp normalize(other), do: handle_trimmed(String.trim(other))

  defp handle_trimmed(<<"\e", rest::binary>>) do
    handle_escape(rest)
  end

  defp handle_trimmed(<<char>>) when char in ?a..?z or char in ?A..?Z,
    do: {:char, <<char>>}

  defp handle_trimmed(other), do: {:char, other}

  defp handle_escape("[A"), do: :up
  defp handle_escape("[B"), do: :down
  defp handle_escape("[C"), do: :right
  defp handle_escape("[D"), do: :left
  defp handle_escape(_), do: :unknown
end
