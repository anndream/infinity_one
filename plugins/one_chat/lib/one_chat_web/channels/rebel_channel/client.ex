defmodule OneChatWeb.RebelChannel.Client do
  @moduledoc """
  Library to handle interaction with the client using the Rebel library.

  This module contains a bunch of helper functions to abstract away the
  details of client interaction. It is uses by a number of application
  modules.

  It contains some generic, and reusable functions, as will as some
  very specialized ones.
  """
  import Rebel.Query
  import Rebel.Core
  import InfinityOneWeb.Utils

  alias Rebel.SweetAlert
  alias OneChatWeb.{ClientView, SharedView, SideNavView, MessageView}
  alias OneChat.{SideNavService}
  alias InfinityOneWeb.Query
  alias OneChatWeb.RoomChannel.Message
  alias InfinityOne.Accounts

  require Logger

  def do_exec_js(socket, js) do
    case exec_js(socket, js) do
      {:ok, res} ->
        res
      {:error, error} = res ->
        Logger.error "Problem with exec_js #{js}, error: #{inspect error}"
        res
    end
  end

  def do_broadcast_js(socket, js) do
    case broadcast_js(socket, js) do
      {:ok, res} ->
        res
      {:error, error} = res ->
        Logger.error "Problem with broadcast_js #{js}, error: #{inspect error}"
        res
      socket ->
        socket
    end
  end

  def page_loading(socket) do
    html = ClientView.page_loading() |> Poison.encode!
    async_js socket, "$('head').prepend(#{html});"
  end

  def remove_page_loading(socket) do
    delete socket, "head > style"
    socket
  end

  def start_loading_animation(socket, elem) do
    socket
    |> page_loading
    |> async_js("$('#{elem}').next().after('#{loading_animation()}')")
  end

  def prepend_loading_animation(socket, selector, colors \\ :default) do
    socket
    |> page_loading()
    |> async_js("$('#{selector}').prepend('#{loading_animation(colors)}')")
  end

  def stop_loading_animation(socket) do
    socket
    |> remove_page_loading()
    |> delete(from: ".loading-animation")
    socket
  end

  def loading_animation(class \\ :default) do
    ClientView.loading_animation(class)
  end

  def set_ucxchat_room(socket, room, display_name, _route \\ "channels") do
    async_js(socket, "window.OneChat.ucxchat.room = '#{room}'; " <>
      "window.OneChat.ucxchat.display_name = '#{display_name}'")
  end

  def push_history(socket, room, display_name, route \\ "channels") do
    socket
    |> set_ucxchat_room(room, display_name, route)
    |> push_history()
  end

  def push_history(socket) do
    async_js(socket, "history.replaceState(history.state, " <>
      "window.OneChat.ucxchat.display_name, '/' + ucxchat.room_route " <>
      "+ '/' + window.OneChat.ucxchat.display_name)")
  end

  def replace_history(socket, room, display_name, route \\ "channels") do
    socket
    |> set_ucxchat_room(room, display_name, route)
    |> replace_history()
  end

  def replace_history(socket) do
    async_js(socket, "history.replaceState(history.state, " <>
      "ucxchat.display_name, '/' + ucxchat.room_route + '/' + " <>
      "ucxchat.display_name)")
  end

  def toastr!(socket, which, message) do
    Logger.info "toastr! has been been deprecated! Please use toastr/3 instead."
    toastr socket, which, message
  end

  def toastr(socket, which, message) do
    message = Poison.encode! message
    async_js socket, ~s{window.toastr.#{which}(#{message});}
  end

  def broadcast_room_icon(socket, room_name, icon_name) do
    do_broadcast_js socket, update_room_icon_js(room_name, icon_name)
  end

  def set_room_icon(socket, room_name, icon_name) do
    do_broadcast_js socket, update_room_icon_js(room_name, icon_name)
  end

  def set_room_title(socket, channel_id, display_name) do
    async_js socket, ~s/$('section[id="chat-window-#{channel_id}"] .room-title').text('#{display_name}')/
  end

  def update_room_icon_js(room_name, icon_name) do
    """
    var elems = document.querySelectorAll('i.room-#{room_name}');
    for (var i=0; i < elems.length; i++) {
      var elem = elems[i];
      elem.className = elem.className.replace(/icon-([a-zA-Z\-_]+)/, 'icon-#{icon_name}');
    }
    """ |> String.replace("\n", "")
  end

  def push_account_header(socket, %{} = user) do
    status = OneChat.PresenceAgent.get user.id

    html = render_to_string SideNavView, "account_box_info.html",
      status: status, user: user

    Query.update socket, :replaceWith, set: html, on: ".side-nav .account-box > .info"
  end

  def push_account_header(socket, user_id) do
    user =
      user_id
      |> Accounts.get_user()
      |> InfinityOne.Hooks.preload_user(Accounts.default_user_preloads())
    push_account_header(socket,  user)
  end

  def push_side_nav_item_link(socket, _user, room) do
    html = render_to_string SideNavView, "chat_room_item_link.html", room: room

    Query.update socket, :replaceWith, set: html,
      on: ~s/.side-nav a.open-room[data-name="#{room.user.username}"]/
  end

  def push_messages_header_icons(socket, chatd) do
    html =
      chatd
      |> SharedView.messages_header_icons()
      |> Phoenix.HTML.safe_to_string()

    Query.update socket, :replaceWith, set: html,
      on: ~s/.messages-container .messages-header-icons/
  end

  def broadcast_room_visibility(socket, payload, false) do
    do_broadcast_js socket, remove_room_from_sidebar(payload.room_name)
  end

  def broadcast_room_visibility(socket, payload, true) do
    push_rooms_list_update socket, payload.channel_id, socket.assigns.user_id
  end

  def remove_room_from_sidebar(room_name) do
    """
    var elem = document.querySelector('aside.side-nav [data-name="#{room_name}"]');
    if (elem) { elem.parentElement.remove(); }
    """ |> String.replace("\n", "")
  end

  def push_message_box(socket, channel_id, user_id) do
    socket
    |> Query.update(:html, set: Message.render_message_box(channel_id, user_id), on: ".room-container footer.footer")
    |> async_js("$('textarea.input-message').focus().autogrow();")
  end

  def broadcast_message_box(socket, channel_id, user_id) do
    html = Message.render_message_box(channel_id, user_id)

    socket
    |> update!(:html, set: html, on: ".room-container footer.footer")
    |> broadcast_js("$('textarea.input-message').autogrow();")
  end

  def push_rooms_list_update(socket, channel_id, user_id) do
    html = SideNavService.render_rooms_list(channel_id, user_id)
    Query.update socket, :html,
      set: html,
      on: "aside.side-nav .rooms-list"
  end

  def update_main_content_html(socket, view, template, bindings) do
    Query.update socket, :html,
      set: render_to_string(view, template, bindings),
      on: ".main-content"
  end

  def update_user_avatar(socket, username, url) do
    async_js socket, ~s/$('.avatar[data-user="#{username}"] .avatar-image').css('background-image', 'url(#{url}');/
  end

  def scroll_bottom(socket, selector) do
    async_js socket, scroll_bottom_js(selector)
  end

  def scroll_bottom_js(selector) do
    """
    var elem = document.querySelector('#{selector}');
    elem.scrollTop = elem.scrollHeight - elem.clientHeight;
    """ |> strip_nl()
  end

  def get_caret_position(socket, selector) do
    exec_js socket, get_caret_position_js(selector)
  end

  def get_caret_position!(socket, selector) do
    case get_caret_position(socket, selector) do
      {:ok, result} -> result
      {:error, _} -> %{}
    end
  end

  def get_caret_position_js(selector) do
    """
    var elem = document.querySelector('#{selector}');
    OneUtils.getCaretPosition(elem);
    """ |> strip_nl
  end

  def set_caret_position(socket, selector, start, finish) do
    async_js socket, set_caret_position_js(selector, start, finish)
  end

  def set_caret_position!(socket, selector, start, finish) do
    case set_caret_position(socket, selector, start, finish) do
      {:ok, result} -> result
      other -> other
    end
  end

  def open_flex_tab(socket) do
    case exec_js socket, ~s/$('#flex-tabs.opened .flex-tab').attr('data-tab')/ do
      {:ok, result} -> result
      {:error, _} -> nil
    end
  end

  def update_flex_channel_name(socket, name) do
    Query.update(socket, :text, set: name, on: ~s(.current-setting[data-edit="name"]))
  end

  def set_caret_position_js(selector, start, finish) do
    """
    var elem = document.querySelector('#{selector}');
    OneUtils.setCaretPosition(elem, #{start}, #{finish});
    """ |> strip_nl
  end

  def more_channels(socket, html) do
    # async_js socket, more_channels_js(html)
    socket
    |> Query.update(:html, set: html, on: ".flex-nav section")
    |> async_js("$('.flex-nav section').parent().removeClass('animated-hidden')")
    |> async_js("$('.arrow').toggleClass('close', 'bottom');")
  end

  def more_channels_js(html) do
    encoded = Poison.encode! html |> strip_nl()
    """
    $('.flex-nav section').html(#{encoded}).parent().removeClass('animated-hidden');
    $('.arrow').toggleClass('close', 'bottom');
    """
  end

  @default_swal_model_opts [
    showCancelButton: true, closeOnConfirm: false, closeOnCancel: true,
    confirmButtonColor: "#DD6B55"
  ]

  @doc """
  Show a SweetAlert modal box.
  """
  # @spec swal_model(Phoenix.Socket.t, String.t, String.t, String.t String.t || nil, Keword.t) :: Phoenix.Socket.t
  def swal_modal(socket, title, body, type, confirm_text, opts \\ []) do
    {swal_opts, callbacks}  = Keyword.pop opts, :opts, []
    swal_opts = Keyword.merge @default_swal_model_opts, swal_opts
    swal_opts =
      if confirm_text do
        Keyword.merge [confirmButtonText: confirm_text] , swal_opts
      else
        swal_opts
      end

    SweetAlert.swal_modal socket, title, body, type, swal_opts, callbacks
  end

  @default_swal_opts [
    timer: 3000, showConfirmButton: false
  ]

  def swal(socket, title, body, type, opts \\ []) do
    opts = Keyword.merge @default_swal_opts, opts
    SweetAlert.swal(socket, title, body, type, opts)
  end


  def update_client_account_setting(socket, :view_mode, value) do
    class =
      case value do
        1 -> ""
        2 -> "cozy"
        3 -> "compact"
      end
    class = "messages-box " <> class

    async_js socket, ~s/$('.messages-container .messages-box').attr('class', '#{class}')/
  end

  def update_client_account_setting(socket, field, value) when field in ~w(hide_avatars hide_usernames)a do
    class = account_settings_to_class field
    cmd =
      if value do
        ~s/addClass('#{class}')/
      else
        ~s/removeClass('#{class}')/
      end

    async_js socket, ~s/$('.messages-container .wrapper').#{cmd}/

  end

  defp account_settings_to_class(:hide_usernames), do: "hide-usernames"
  defp account_settings_to_class(:hide_avatars), do: "hide-avatars"

  @doc """
  Update message role tags for a given user.

  Handles adding and remove message role tags for the given username.
  """
  def update_users_role(socket, "delete", username, role) do
    broadcast_js(socket, ~s/$('.messages-box li.message[data-username="#{username}"] .role-tag[data-role="#{role}"]').remove()/)
    socket
  end

  def update_users_role(socket, "insert", username, role) do
    html = render_to_string(OneChatWeb.MessageView, "message_tag.html", tag: role) |> Poison.encode!
    async_js(socket, ~s/$('.messages-box li.message[data-username="#{username}"] .info').prepend(#{html})/)
    socket
  end

  def update_users_role(socket, action, username, role) do
    Logger.warn "unsupported action: #{inspect action} for user: #{inspect username}, role: #{inspect role}"
    socket
  end

  def update_pin(socket, _action, _channel_id) do
    tab_name = "pinned-messages"
    if open_flex_tab(socket) == tab_name do
      OneUiFlexTab.FlexTabChannel.refresh_open(socket, tab_name)
    end
    socket
  end

  def update_star(socket, _action, _channel_id) do
    tab_name = "starred-messages"
    if open_flex_tab(socket) == tab_name do
      OneUiFlexTab.FlexTabChannel.refresh_open(socket, tab_name)
    end
    socket
  end

  def update_mention(socket, _action, _channel_id) do
    tab_name = "mentions"
    if open_flex_tab(socket) == tab_name do
      OneUiFlexTab.FlexTabChannel.refresh_open(socket, tab_name)
    end
    socket
  end

  def add_caution_announcement(socket, body) do
    html =
      MessageView
      |> render_to_string("caution_announcement.html", text: body)
      |> Poison.encode!

    async_js socket, ~s/$('.messages-container header.fixed-title').after(#{html})/
  end

  def add_announcement(socket, body) do
    html =
      MessageView
      |> render_to_string("announcement.html", text: body)
      |> Poison.encode!

    async_js socket, ~s/$('.messages-container header.fixed-title').after(#{html})/
  end

  def download_cert(socket, path, name) do
    link = """
      var link = document.createElement('a');
      link.download = '#{name}';
      link.href = '#{path}';
      link.target = '_blank';
      link.click();
      """ |> String.replace("\n", "")
    async_js(socket, link)
  end

  def slow_delete(socket, selector) do
    async_js(socket, """
      var target = #{selector};
      target.hide('slow', function() { target.remove(); });
      """ |> String.replace("\n", ""))
  end

  @doc """
  Execute the JS on the client to update presence status and status messages
  for the appropriate markup. Only changes status if require. It only affects
  message markup too.

  Not sure if we want to constrain it to just messages, so need to review after
  we get more experience with it.
  """
  def refresh_users_status(socket, username, status, status_message) do
    socket
    |> async_js("""
      let elems = $('.message [data-status-name="#{username}"]:not(.status-#{status})');
      for (let i=0;i<elems.length;i++) {
        let elem = elems[i];
        elem.className = elem.className.replace(/status-[a-zA-Z]+/, 'status-#{status}');
      }
      """ |> String.replace("\n", ""))
    |> Query.update(:text, set: status_message, on: ~s(.message .status-message[data-username="#{username}"]))
  end
end
