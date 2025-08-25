defmodule ExStorage.TUI.Screen do
  @callback onload(state :: map()) :: any()
  @callback render(state :: map()) :: any()
  @callback handle_event(state :: map(), event :: term()) ::
              {:same, map()}
              | {:keep, map()}
              | {module(), map()}
              | {:quit, map()}
end
