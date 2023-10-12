defmodule ChatWeb.PageLive do
  use Phoenix.LiveView
  require Logger
  alias Chat.Authenticator

  @impl true
  def render(assigns) do
    ~L"""
      <%= if @is_join_clicked? do %>
        <form method="post" phx-submit="verify-room">
          <label for="room-key">Room key:</label>
          <input type="text" placeholder="Enter room key..." required name="room_key" value="">
          <button type="submit">verify</button>
        </form>
        <% else %>
          <button phx-click="random-room">Create a chat room</button><br>
          <button phx-click="join-room">Join chat room</button><br>
          <button phx-click="public-rooms">View all available rooms</button>
      <% end %>
    """
  end

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, is_join_clicked?: false)}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}

  @impl true
  def handle_event("random-room", _unsigned_params, socket) do
    random_slugs = "/" <> (MnemonicSlugs.generate_slug(3) |> Authenticator.generate_key())
    {:noreply, push_navigate(socket, to: random_slugs)}
  end

  @impl true
  def handle_event("join-room", _unsigned_params, socket) do
    {:noreply, assign(socket, is_join_clicked?: true)}
  end

  @impl true
  def handle_event("verify-room", %{"room_key" => room_key}, socket) do
    {:noreply, redirect(socket, to: "/#{String.trim(room_key)}")}
  end

  def handle_event("public-rooms", _, socket) do
    {:noreply, redirect(socket, to: "/all")}
  end
end
