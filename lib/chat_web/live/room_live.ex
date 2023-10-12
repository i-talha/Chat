defmodule ChatWeb.RoomLive do
  use Phoenix.LiveView

  require Logger

  alias Chat.Authenticator

  @spec handle_params(map(), String.t(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}

  @impl true
  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket}
  end

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}

  @impl true
  def mount(%{"id" => room_id}, _session, socket) do
    {:ok, room_name} = Authenticator.verify_room(room_id)
    topic = "room:" <> room_name
    username = MnemonicSlugs.generate_slug(2)
    ChatWeb.Endpoint.subscribe(topic)
    ChatWeb.Presence.track(self(), topic, username, %{})

    {:ok,
     assign(socket,
       room_id: room_id,
       room_name: room_name,
       topic: topic,
       message: "",
       username: username,
       messages: [],
       show_key?: false,
       writer: "",
       user_list: [],
       temporary_assigns: [messages: []]
     )}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}

  @impl true
  def handle_event(
        "submit-message",
        %{"message" => message},
        %{assigns: %{username: username, topic: topic}} = socket
      ) do
    message = %{uuid: UUID.uuid4(), username: username, content: message}
    Logger.info(message: message)
    ChatWeb.Endpoint.broadcast(topic, "new-message", message)
    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("hide-key", _unsigned_params, socket) do
    {:noreply, assign(socket, show_key?: false)}
  end

  @impl true
  def handle_event(
        "typing",
        %{"message" => message},
        %_{assigns: %{topic: topic, username: username}} = socket
      ) do
    if String.length(message) > 0 do
      ChatWeb.Endpoint.broadcast_from(self(), topic, "typing", username <> " is typing..")
      {:noreply, socket}
    else
      ChatWeb.Endpoint.broadcast_from(self(), topic, "cancel-typing", "")
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("show-key", _unsigned_params, socket) do
    {:noreply, assign(socket, show_key?: true)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    Logger.info(payload: message)

    {:noreply,
     assign(socket,
       messages: [message]
     )}
  end

  @spec handle_info(map(), Phoenix.LiveView.Socket.t()) :: {:noreply, Phoenix.LiveView.Socket.t()}

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{leaves: leaves, joins: joins}},
        %{assigns: %{topic: topic}} = socket
      ) do
    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username ->
        %{uuid: UUID.uuid4(), content: "#{username} joined", username: "SYSTEM", type: :system}
      end)

    user_list =
      ChatWeb.Presence.list(topic)
      |> Map.keys()

    Logger.info(user_list: user_list)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username ->
        %{uuid: UUID.uuid4(), content: "#{username} leaved", username: "SYSTEM", type: :system}
      end)

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end

  @impl true
  def handle_info(%{event: "typing", payload: msg}, socket) do
    Logger.info(writer: msg)
    {:noreply, assign(socket, writer: msg, show_key?: true)}
  end

  @impl true
  def handle_info(%{event: "cancel-typing"}, socket) do
    {:noreply, assign(socket, writer: "")}
  end

  @spec display_message(map()) :: Phoenix.LiveView.Rendered.t()

  def display_message(assigns) do
    if Map.has_key?(assigns, :type) do
      %{type: :system, content: content, uuid: uuid} = assigns

      ~L"""
      <li class="message-content" style="text-align: center;" id="<%= uuid %>">
        <em ><%= content %></em>
      </li>
      """
    else
      %{content: content, uuid: uuid, username: username} = assigns

      ~L"""
      <li class="message-content" id="<%= uuid %>">
        <strong><%= username %>: </strong><%= content %>
      </li>
      """
    end
  end
end
