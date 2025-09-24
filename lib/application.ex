defmodule ExStorage.Application do
  @moduledoc false
  alias ExStorage.Core.Worker.FormatService
  alias ExStorage.Core.Worker.GenreService
  alias ExStorage.Core.Worker.WorkService
  
  use Application

  def start(_type, _args) do
    session_id = generate_session_id()

    children = [
      {ExStorage.Log.Logger, session_id},
      ExStorage.DB.Supervisor,
      Supervisor.child_spec(
        {ExStorage.Core.Worker.StateServer, format_deps()},
        id: FormatService.pid()
      ),
      Supervisor.child_spec(
        {ExStorage.Core.Worker.StateServer, genre_deps()},
        id: GenreService.pid()
      ),
      Supervisor.child_spec(
        {ExStorage.Core.Worker.StateServer, work_deps()},
        id: WorkService.pid()
      ),
      ExStorage.TUI.Loop
    ]

    opts = [strategy: :one_for_one, name: ExStorage.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp generate_session_id do
    DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()
  end

  defp work_deps do
    serv = Application.get_env(:ex_storage, :work_serv, WorkService)
    repo = Application.get_env(:ex_storage, :work_repo, ExStorage.DB.SurrealDB.WorkRepository)
    {WorkService.pid(), serv, repo}
  end

  defp format_deps do
    serv = Application.get_env(:ex_storage, :format_serv, FormatService)
    repo = Application.get_env(:ex_storage, :format_repo, ExStorage.DB.Local.FormatRepository)
    {FormatService.pid, serv, repo}
  end

  defp genre_deps do
    serv = Application.get_env(:ex_storage, :format_serv, GenreService)
    repo = Application.get_env(:ex_storage, :format_repo, ExStorage.DB.Local.GenreRepository)
    {GenreService.pid, serv, repo}
  end
end
