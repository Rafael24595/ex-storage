defmodule ExStorage.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    session_id = generate_session_id()

    children = [
      {ExStorage.Log.Logger, session_id},
      ExStorage.Core.StateServer,
      ExStorage.DB.ClientSupervisor,
      ExStorage.TUI.Loop
    ]
    opts = [strategy: :one_for_one, name: ExStorage.Supervisor]
    Supervisor.start_link(children, opts)

  end

  defp generate_session_id do
    DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
  end
end
