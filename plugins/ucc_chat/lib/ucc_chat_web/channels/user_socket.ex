defmodule UccChatWeb.UserSocket do
  use Phoenix.Socket

  import Rebel.Query

  alias UcxUcc.Accounts.User
  alias UcxUcc.Repo
  alias UccChatWeb.RoomChannel.Message, as: WebMessage

  require UccChat.ChatConstants, as: CC
  require Logger

  ## Channels
  channel CC.chan_room <> "*", UccChatWeb.RoomChannel    # "ucxchat:"
  channel CC.chan_user <> "*", UccChatWeb.UserChannel  # "user:"
  channel CC.chan_system <> "*", UccChatWeb.SystemChannel  # "system:"
  # channel CC.chan_client <> "*", MscsWeb.ClientChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the user and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  def connect(%{"token" => token, "tz_offset" => tz_offset}, socket) do
    # Logger.warn "socket connect params: #{inspect params}, socket: #{inspect socket}"
    case Coherence.verify_user_token(socket, token, &assign/3) do
      {:error, _} -> :error
      {:ok, %{assigns: %{user_id: user_id}} = socket} ->
        case User.user_id_and_username(user_id) |> Repo.one do
          nil ->
            :error
          {user_id, username} ->
            {
              :ok,
              socket
              |> assign(:user_id, user_id)
              |> assign(:username, username)
              |> assign(:tz_offset, tz_offset)
            }
        end
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     UcxUccWeb.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"

  def push_message_box(socket, channel_id, user_id) do
    Logger.debug "push_message_box #{channel_id}, #{user_id}, " <>
      "socket.assigns: #{inspect socket.assigns}"

    update socket, :html,
      set: WebMessage.render_message_box(channel_id, user_id),
      on: ".room-container footer.footer"
  end

  def broadcast_message_box(socket, channel_id, user_id) do
    update! socket, :html,
      set: WebMessage.render_message_box(channel_id, user_id),
      on: ".room-container footer.footer"
  end

  # def push_rooms_list_update(socket, channel_id, user_id) do
  #   Phoenix.Channel.push socket, "code:update", %{
  #     html: SideNavService.render_rooms_list(channel_id, user_id),
  #     selector: "aside.side-nav .rooms-list",
  #     action: "html"
  #   }
  # end
end
