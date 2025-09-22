defmodule ExStorage.DB.Local.FormatState do

  defstruct [
    :items
  ]

  @type t :: %__MODULE__{
    items: list(),
  }

  def new_state(items) do
    %ExStorage.DB.Local.FormatState{
      items: items,
    }
  end
end
