defmodule ExStorage.DB.ClientSupervisor do
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      {ExStorage.DB.Client, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
