defmodule ExStorage.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      ExStorage.Core.StateServer,
      ExStorage.DB.ClientSupervisor,
      ExStorage.TUI.Loop
    ]
    opts = [strategy: :one_for_one, name: ExStorage.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
