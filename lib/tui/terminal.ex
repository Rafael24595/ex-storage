defmodule Terminal do
  def clear, do: IO.write("\e[2J\e[H")
  
  def enable_raw_mode do
    if unix?() do
      System.cmd("stty", ["-echo", "raw"])
    else
      :ok
    end
  end

  def disable_raw_mode do
    if unix?() do
      System.cmd("stty", ["echo", "icanon"])
    else
      :ok
    end
  end

  defp unix? do
    case :os.type() do
      {:unix, _} -> true
      _ -> false
    end
  end
end
