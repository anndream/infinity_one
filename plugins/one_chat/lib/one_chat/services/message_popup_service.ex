defmodule OneChat.MessagePopupService do
  use OneChat.Shared, :service

  import Ecto.Query

  alias InfinityOne.Accounts
  alias OneChat.{Channel, SlashCommands, PresenceAgent, Emoji}
  alias InfinityOne.Repo
  alias InfinityOne.Accounts.User
  alias OneChatWeb.MessageView
  alias OneChat.Schema.Message, as: MessageSchema
  # alias OneChat.ServiceHelpers, as: Helpers

  require Logger

  def handle_in("get:users" <> _mod, msg) do
    Logger.debug "get:users, msg: #{inspect msg}"
    pattern = msg["pattern"] |> to_string
    users =
      msg["channel_id"]
      |> get_users_by_pattern(msg["user_id"], "%" <> pattern <> "%")

    if length(users) > 0 do
      data = users ++ [
        %{
          system: true,
          username: "all",
          name: ~g"Notify all in this room", id: "all"
        },
        %{
          system: true,
          username: "here",
          name: ~g"Notify active users in this room",
          id: "here"
        }
      ]

      chatd = %{open: true, title: ~g"People", data: data, templ: "popup_user.html"}

      html =
        "popup.html"
        |> MessageView.render(chatd: chatd)
        |> Helpers.safe_to_string

      {:ok, %{html: html}}
    else
      {:ok, %{close: true}}
    end
  end

  def handle_in("get:channels" <> _mod, msg) do
    Logger.debug "get:channels, msg: #{inspect msg}"
    pattern = msg["pattern"] |> to_string
    channels = get_channels_by_pattern(msg["channel_id"], msg["user_id"],
      "%" <> pattern <> "%")

    if length(channels) > 0 do
      chatd = %{
        open: true,
        title: ~g"Channels",
        data: channels,
        templ: "popup_channel.html"
      }

      html =
        "popup.html"
        |> MessageView.render(chatd: chatd)
        |> Helpers.safe_to_string

      {:ok, %{html: html}}
    else
      {:ok, %{close: true}}
    end
  end

  def handle_in("get:slashcommands" <> _mod, msg) do
    Logger.debug "get:slashcommands, msg: #{inspect msg}"
    pattern = msg["pattern"] |> to_string

    if commands = SlashCommands.commands(pattern) do
      chatd = %{open: true, data: commands}

      html =
        "popup_slash_commands.html"
        |> MessageView.render(chatd: chatd)
        |> Helpers.safe_to_string

      {:ok, %{html: html}}
    else
      {:ok, %{close: true}}
    end
  end

  def handle_in(ev = "get:emojis", msg) do
    pattern = msg["pattern"] |> to_string
    Logger.debug "#{ev}, pattern: #{pattern} msg: #{inspect msg}"


    case Emoji.commands(pattern) do
      [] ->
        {:ok, %{close: true}}
      commands ->
        chatd = %{
          open: true,
          title: "Emoji",
          data: commands,
          templ: "popup_emoji.html"
        }

        html =
          "popup_emoji.html"
          |> MessageView.render(chatd: chatd)
          |> Helpers.safe_to_string

        {:ok, %{html: html}}
    end
  end

  def get_users_by_pattern(channel_id, user_id, pattern) do
    channel_users = get_default_users(channel_id, user_id, pattern)
    case length channel_users do
      max when max >= 5 -> channel_users
      size ->
        exclude = Enum.map(channel_users, &(&1[:id]))
        channel_users ++ get_all_users(pattern, exclude, 5 - size)
    end

  end

  def get_channels_by_pattern(_channel_id, user_id, pattern) do
    user_id
    |> Channel.get_authorized_channels
    |> where([c], like(c.name, ^pattern))
    |> order_by([c], asc: c.name)
    |> limit(5)
    |> select([c], {c.id, c.name})
    |> Repo.all
    # |> Enum.filter(fn {id, name} -> InfinityOne.Permissions.has_permission?())
    |> Enum.map(fn {id, name} -> %{id: id, name: name, username: name} end)
  end

  def get_all_users(pattern, exclude, count) do
    User
    |> where([c], like(c.username, ^pattern) and not c.id in ^exclude)
    |> join(:left, [c], r in assoc(c, :roles))
    |> preload([c, r], [roles: c])
    |> select([c], c)
    |> order_by([c], asc: c.username)
    |> limit(^count)
    |> Repo.all
    |> Enum.reject(fn user -> Accounts.has_role?(user, "bot") end)
    |> Enum.map(fn user ->
      %{id: user.id, username: user.username,
        status: PresenceAgent.get(user.id)}
    end)
  end

  def get_default_users(channel_id, user_id, pattern \\ "%") do
    user_ids =
      MessageSchema
      |> where([m], m.channel_id == ^channel_id and m.user_id != ^user_id)
      |> group_by([m], m.user_id)
      |> select([m], m.user_id)
      |> Repo.all
      |> Enum.reverse

    User
    |> where([c], like(c.username, ^pattern) and c.id in ^user_ids)
    |> join(:left, [c], r in assoc(c, :roles))
    |> preload([c, r], [roles: c])
    |> select([c], c)
    |> Repo.all
    |> Enum.reject(fn user -> Accounts.has_role?(user, "bot") end)
    |> Enum.reverse
    |> Enum.take(5)
    |> Enum.map(fn user ->
      %{username: user.username, id: user.id,
        status: PresenceAgent.get(user.id)}
    end)
  end

  # defp add_status(users) do
  #   users
  #   |> Enum.map(fn user ->
  #     Map.put(user, :status, PresenceAgent.get(user.id))
  #   end)
  # end
end
