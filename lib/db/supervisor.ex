defmodule ExStorage.DB.Supervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    work_repository = Application.get_env(:ex_storage, :work_repository, ExStorage.DB.SurrealDB.WorkRepository)
    format_repository = Application.get_env(:ex_storage, :format_repository, ExStorage.DB.Local.FormatRepository)
    genre_repository = Application.get_env(:ex_storage, :genre_repository, ExStorage.DB.Local.GenreRepository)

    children = [
      work_repository,
      format_repository,
      genre_repository
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
