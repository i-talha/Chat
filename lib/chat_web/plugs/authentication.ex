defmodule ChatWeb.Plugs.Authentication do
  import Plug.Conn
  import Phoenix.Controller
  alias Chat.Authenticator

  def init(_) do
  end

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()

  def call(%_{params: %{"id" => room_key}} = conn, _params) do
    case Authenticator.verify_room(room_key) do
      {:ok, _room_name} ->
        conn

      {:error, msg} ->
        put_flash(conn, :error, msg)
        |> redirect(to: "/")
        |> halt()
    end
  end
end
