defmodule AvalonWeb.Router do
  use AvalonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", AvalonWeb do
    pipe_through :api
  end
end
