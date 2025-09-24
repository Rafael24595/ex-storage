defmodule ExStorage.DB.Local.EnumState do

  defstruct [
    :file,
    :items,
  ]

  @type t :: %__MODULE__{
    file: String.t(),
    items: list()
  }

  def new_state(file, items) do
    %ExStorage.DB.Local.EnumState{
      file: file,
      items: items,
    }
  end
end
