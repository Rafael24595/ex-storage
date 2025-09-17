defmodule ExStorage.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    session_id = generate_session_id()

    work_serv = get_work_serv()
    work_repo = get_work_repo()

    children = [
      {ExStorage.Log.Logger, session_id},
      {ExStorage.Core.Worker.StateServer, {:work, work_serv, work_repo}},
      ExStorage.DB.ClientSupervisor,
      ExStorage.TUI.Loop
    ]
    opts = [strategy: :one_for_one, name: ExStorage.Supervisor]
    Supervisor.start_link(children, opts)

  end

  defp generate_session_id do
    DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
  end

    defp get_work_serv do
   Application.get_env(:ex_storage, :work_serv, ExStorage.Core.Worker.WorkService)
  end

   defp get_work_repo do
   Application.get_env(:ex_storage, :work_repo, ExStorage.DB.SurrealDB.WorkRepository)
  end
end
