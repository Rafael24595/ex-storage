defmodule ExStorage.Application do
  @moduledoc false
  alias ExStorage.Core.Worker.FormatService
  alias ExStorage.Core.Worker.WorkService
  use Application

  def start(_type, _args) do
    session_id = generate_session_id()

    format_pid = FormatService.pid()
    format_serv = get_format_serv()
    format_repo = get_format_repo()

    work_pid = WorkService.pid()
    work_serv = get_work_serv()
    work_repo = get_work_repo()

    children = [
      {ExStorage.Log.Logger, session_id},
      ExStorage.DB.Supervisor,
      Supervisor.child_spec(
        {ExStorage.Core.Worker.StateServer, {format_pid, format_serv, format_repo}},
        id: format_pid
      ),
      Supervisor.child_spec(
        {ExStorage.Core.Worker.StateServer, {work_pid, work_serv, work_repo}},
        id: work_pid
      ),
      ExStorage.TUI.Loop
    ]

    opts = [strategy: :one_for_one, name: ExStorage.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp generate_session_id do
    DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
  end

  defp get_work_serv do
    Application.get_env(:ex_storage, :work_serv, WorkService)
  end

  defp get_work_repo do
    Application.get_env(:ex_storage, :work_repo, ExStorage.DB.SurrealDB.WorkRepository)
  end

  defp get_format_serv do
    Application.get_env(:ex_storage, :format_serv, FormatService)
  end

  defp get_format_repo do
    Application.get_env(:ex_storage, :format_repo, ExStorage.DB.Local.FormatRepository)
  end
end
