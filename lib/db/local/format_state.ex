defmodule ExStorage.DB.Local.FormatState do

  defstruct [
    :items
  ]

  @type t :: %__MODULE__{
    items: list(),
  }

  def new_state() do
    %ExStorage.DB.Local.FormatState{
      items: [],
    }
  end
end
