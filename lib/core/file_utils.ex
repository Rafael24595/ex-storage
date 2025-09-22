defmodule ExStorage.Core.FileUtils do
  def read_json(file) do
    case File.read(file) do
      {:ok, body} ->
        case Jason.decode(body) do
          {:ok, data} ->
            {:ok, data}

          {:error, reason} ->
            {:error, "Error during JSON parsing: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Error during file reading: #{inspect(reason)}"}
    end
  end

  def read_json(file, decoder) do
    case read_json(file) do
      {:ok, body} ->
        case decoder.(body) do
          {:ok, data} ->
            {:ok, data}

          {:error, reason} ->
            {:error, "Error during JSON deserialize: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
