defmodule UccChatWeb.SharedView do
  use UcxUcc.Utils
  use UcxUccWeb.Gettext

  import Phoenix.HTML.Tag, warn: false

  alias UcxUcc.{Permissions, Repo, Accounts, Accounts.User, Hooks}
  alias UccChat.{Subscription, ChatDat}

  require Logger

  def markdown(text), do: text

  def get_all_users do
    Repo.all User
  end

  def get_status(user) do
    UccChat.PresenceAgent.get(user.id)
  end

  def get_room_icon_class(data, status \\ nil)

  def get_room_icon_class(%ChatDat{} = chatd, status) do
    status = status || get_room_status(chatd)
    [
      get_room_icon(chatd),
      "status-" <> status,
      "room-" <> chatd.active_room[:name]
    ]
    |> Enum.join(" ")
  end

  def get_room_icon_class(%{} = room, status) do
    status = status || room[:user_status]
    [
      room[:room_icon],
      "status-" <> status,
      "room-" <> room[:name]
    ]
    |> Enum.join(" ")
  end

  def get_room_icon(chatd), do: chatd.room_map[chatd.channel.id][:room_icon]
  def get_room_status(chatd) do
    # Logger.error "get room status room_map: #{inspect chatd.room_map[chatd.channel.id]}"
    chatd.room_map[chatd.channel.id][:user_status]
  end
  def get_room_display_name(chatd), do: chatd.room_map[chatd.channel.id][:display_name]

  def hidden_on_nil(test, prefix \\ "")
  def hidden_on_nil(_test, ""), do: " hidden"
  def hidden_on_nil(test, prefix) when is_falsy(test), do: " #{prefix}hidden"
  def hidden_on_nil(_, _), do: ""

  def map_field(map, field, default \\ "")
  def map_field(%{} = map, field, default), do: Map.get(map, field, default)
  def map_field(_, _, default), do: default

  def get_ftab_open_class(nil), do: ""
  def get_ftab_open_class(_), do: "opened"

  def get_room_notification_sounds do
    [
      {~g"None", "none"},
      {~g"Use system preferences (Default)", "system_default"},
      {~g"Door (Default)", "door"},
      {~g"Beep", "beep"},
      {~g"Chelle", "chelle"},
      {~g"Ding", "ding"},
      {~g"Droplet", "droplet"},
      {~g"Highbell", "highbell"},
      {~g"Seasons", "seasons"}
    ]
  end
  def get_message_notification_sounds do
    [
      {~g"None", "none"},
      {~g"Use room and system preferences (Default)", "system_default"},
      {~g"Chime (Default)", "chime"},
      {~g"Beep", "beep"},
      {~g"Chelle", "chelle"},
      {~g"Ding", "ding"},
      {~g"Droplet", "droplet"},
      {~g"Highbell", "highbell"},
      {~g"Seasons", "seasons"}
    ]
  end

  @regex1 ~r/^(.*?)(`(.*?)`)(.*?)$/
  @regex2 ~r/\A(```(.*)```)\z/Ums

  def format_quoted_code(string, _, true), do: string
  def format_quoted_code(string, true, _) do
    do_format_multi_line_quoted_code(string)
  end
  def format_quoted_code(string, _, _) do
    do_format_quoted_code(string, "")
  end

  def do_format_quoted_code(string, acc \\ "")
  def do_format_quoted_code("", acc), do: acc
  def do_format_quoted_code(nil, acc), do: acc
  def do_format_quoted_code(string, acc) do
    case Regex.run(@regex1, string) do
      nil -> acc <> string
      [_, head, _, quoted, tail] ->
        acc = acc <> head <> " " <> single_quote_code(quoted)
        do_format_quoted_code(tail, acc)
    end
  end

  def do_format_multi_line_quoted_code(string) do
    case Regex.run(@regex2, string) do
      nil -> string
      [_, _, quoted] ->
        multi_quote_code quoted
    end
  end

  # def multi_quote_code(quoted) do
  #   """
  #   <pre>
  #     <code class='code-colors'>
  #       #{quoted}
  #     </code>
  #   </pre>
  #   """
  # end
  def multi_quote_code(quoted) do
    "<pre><code class='code-colors'>#{quoted}</code></pre>"
  end

  def single_quote_code(quoted) do
    """
    <span class="copyonly">`</span>
    <span>
      <code class="code-colors inline">#{quoted}</code>
    </span>
    <span class="copyonly">`</span>
    """
  end

  def get_avatar_img(username, size \\ "40x40") do
    # Logger.warn "get_avatar #{inspect msg}"
    # ""
    Phoenix.HTML.Tag.tag :img, src: "https://robohash.org/#{username}.png?set=any&bgset=any&size=#{size}"
  end

  def get_avatar(msg) do
    # Logger.warn "get_avatar #{inspect msg}"
    # ""
    # Phoenix.HTML.Tag.tag :img, src: "https://robohash.org/#{msg}.png?size=40x40"
    "https://robohash.org/#{msg}.png?set=any&bgset=any&size=40x40"
  end
  def get_large_avatar(username) do
    # Phoenix.HTML.Tag.tag :img, src: "https://robohash.org/#{username}.png?size=350x310"
    "https://robohash.org/#{username}.png?set=any&bgset=any&size=350x310"
  end

  def has_permission?(user, permission, scope \\ nil), do: Permissions.has_permission?(user, permission, scope)
  def has_role?(user, role, scope), do: Accounts.has_role?(user, role, scope)
  def has_role?(user, role), do: Accounts.has_role?(user, role)

  def user_muted?(%{} = user, channel_id), do: UccChat.ChannelService.user_muted?(user.id, channel_id)

  def content_home_title do
    "test"
  end

  def content_home_body do
    "test"
  end

  def subscribed?(user_id, channel_id) do
    Subscription.subscribed?(channel_id, user_id)
  end

  def view_url(url) do
    String.replace url, ~r/(.*?priv\/static)/, ""
  end

  @doc """
  Get the avatar url for a given User.

  Can be called with either a User struct or a username with the following
  behaviour:

  Called with:

  * username - Fetches the default initials based avatar for the user's initials
  * user struct - Doses the following
    1. Uses the uploaded Avatar image if one exists
    1. Uses the avatar_url field if its not empty
    1. Fetches the default initials based avatar.
  """
  def avatar_url(user, size \\ :thumb)

  def avatar_url(%{avatar: %{} = avatar} = user, size) do
    {avatar, user}
    |> UccChat.Avatar.url(size)
    |> view_url
  end

  def avatar_url(%{avatar_url: url}, _) when not url in [nil, ""] do
    url
  end

  def avatar_url(%{avatar: nil} = user, _) do
    avatar_url user.username
  end

  def avatar_url(username, _) do
    UccChat.AvatarService.avatar_url username
  end

  def avatar_background_tags(user, type \\ :thumb) do
    content_tag :div, [class: "avatar", "data-user": user.username] do
      content_tag :div, [class: "avatar-image",
        style: ~s/background-image: url(#{avatar_url(user, type)});/], do: ""
    end
  end

  def user_details_thead_hook do
    Hooks.user_details_thead_hook []
  end

  def user_details_body_hook(user) do
    Hooks.user_details_body_hook [], user
  end

  def user_card_details(user) do
    Hooks.user_card_details [], user
  end

  def user_list_item_hook(user) do
    Hooks.user_list_item_hook [], user
  end

  def messages_header_icons(chatd) do
    Hooks.messages_header_icons [], chatd
  end

  def account_box_header(user) do
    Hooks.account_box_header [], user
  end

  def nav_option_buttons do
    Hooks.nav_option_buttons []
  end

  defmacro gt(text, opts \\ []) do
    quote do
      gettext(unquote(text), unquote(opts))
    end
  end
end
