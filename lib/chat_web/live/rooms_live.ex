defmodule ChatWeb.RoomsLive do
  use Phoenix.LiveView
  alias Chat.KeyManager

  def mount(_, _, socket) do
    rooms = KeyManager.all_public_room()
    {:ok, assign(socket, rooms: rooms)}
  end

  def handle_event("join-room", %{"room" => room_id}, socket) do
    {:noreply, redirect(socket, to: "/#{room_id}")}
  end
end
