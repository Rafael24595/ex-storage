defmodule ExStorageWeb.ApiController do
  use ExStorageWeb, :controller

  def hello_world(conn, _params) do
    json(conn, %{message: "Hello ExStorage"})
  end
end
