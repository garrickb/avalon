defmodule Avalon.PageController do
  use Avalon.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
