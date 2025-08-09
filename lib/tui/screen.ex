defmodule ExStorage.TUI.Screen do
  @callback render(state :: map()) :: any()
  @callback handle_event(state :: map(), event :: term()) ::
              {:same, map()}
              | {module(), map()}
              | {:quit, map()}
end
