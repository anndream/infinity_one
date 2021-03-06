defmodule OneChatWeb.Client do
  @moduledoc """
  An interface to the Clint Application.
  """
  use OneChatWeb.RoomChannel.Constants

  import InfinityOneWeb.Utils
  import Rebel.Query, warn: false
  import Rebel.Core, except: [broadcast_js: 2, async_js: 2]

  alias Rebel.Element
  alias OneChatWeb.RebelChannel.Client, as: RebelClient
  alias InfinityOneWeb.Query

  require Logger
  # alias Rebel.Element

  @wrapper       ".messages-box .wrapper"
  @wrapper_list  @wrapper <> " > ul"

  def send_js(socket, js) do
    exec_js socket, strip_nl(js)
  end

  def send_js!(socket, js) do
    exec_js! socket, strip_nl(js)
  end

  # not sure how to do this
  def closest(socket, selector, class, attr) do
    exec_js! socket, """
      var el = document.querySelector('#{selector}');
      el = el.closest('#{class}');
      if (el) {
        el.getAttribute('#{attr}');
      } else {
        null;
      }
      """
  end

  def append(socket, selector, html) do
    Rebel.Query.insert socket, html, append: selector
  end

  def replace_with(socket, selector, html) do
    Query.update socket, :replaceWith, set: html, on: selector
  end

  def html(socket, selector, html) do
    Query.update socket, :html, set: html, on: selector
  end

  def remove_closest(socket, selector, parent, children) do
    js =
      ~s/$('#{selector}').closest('#{parent}').find('#{children}').remove()/
    # Logger.warn "remove closest js: #{inspect js}"
    async_js socket, js
    socket
  end

  def close_popup(socket) do
    Query.update socket, :html, set: "", on: ".message-popup-results"
  end

  def has_class?(socket, selector, class) do
    exec_js! socket,
      "document.querySelector('#{selector}').classList.contains('#{class}')"
  end

  def editing_message?(socket) do
    has_class?(socket, @message_box, "editing")
  end

  def get_message_box_value(socket) do
    exec_js! socket, "document.querySelector('#{@message_box}').value;"
  end

  def set_message_box_focus(socket) do
    async_js socket, set_message_box_focus_js()
  end

  def set_message_box_focus_js,
    do: "var elem = document.querySelector('#{@message_box}'); elem.focus();"

  def clear_message_box(socket) do
    assigns = socket.assigns
    socket
    |> OneChatWeb.RebelChannel.Client.push_message_box(assigns.channel_id, assigns.user_id)
    |> set_inputbox_buttons(false)
  end

  def clear_message_box_js,
    do: set_message_box_focus_js() <> ~s(elem.value = "";)

  def render_popup_results(html, socket) do
    Query.update socket, :html, set: html, on: ".message-popup-results"
  end

  def get_selected_item(socket) do
    case Element.query_one socket, ".popup-item.selected", :dataset do
      {:ok, %{"dataset" => %{"name" => name}}} -> name
      _other -> nil
    end
  end

  def push_message({message, html}, socket) do
    async_js socket, push_message_js(html, message) <>
      RebelClient.scroll_bottom_js('#{@wrapper}')
  end

  def push_update_message({message, html}, socket) do
    socket
    |> Query.update(:replaceWith, set: html,
      on: ~s/#{@wrapper_list} li[id="#{message.id}"]/)
    |> async_js("OneChat.roomManager.updateMentionsMarksOfRoom()")
  end

  def push_update_reactions({message, html}, socket) do
    socket
    |> Query.update(:replaceWith, set: html,
      on: ~s/#{@wrapper_list} li[id="#{message.id}"] ul.reactions/)
    |> async_js("if (OneUtils.is_scroll_bottom(50)) { OneUtils.scroll_bottom(); }")
  end

  def push_message_js(html, message) do
    encoded = Poison.encode! html
    """
    var node = document.createRange().createContextualFragment(#{encoded});
    var elem = document.querySelector('#{@wrapper_list}');
    var at_bottom = OneUtils.is_scroll_bottom(30);
    var user_id = '#{message.user_id}';
    var id = '#{message.id}';
    elem.appendChild(node);
    Rebel.set_event_handlers('[id="#{message.id}"]');
    OneChat.normalize_message(id);
    if (at_bottom || user_id == ucxchat.user_id) {
      OneUtils.scroll_bottom();
    }
    OneChat.roomManager.updateMentionsMarksOfRoom();
    OneChat.roomManager.new_message(id, user_id);
    """
  end

  def broadcast_message({message, html}, socket) do
    js = push_message_js(html, message)
    broadcast_js socket, js
  end

  def broadcast_update_message({message, html}, socket) do
    broadcast_js socket, update_message_js(html, message)
  end

  def update_message_js(html, message) do
    encoded = Poison.encode! html
    """
    $('[id="#{message.id}"]').replaceWith(#{encoded});
    Rebel.set_event_handlers('[id="#{message.id}"]');
    OneChat.normalize_message('#{message.id}');
    OneChat.roomManager.updateMentionsMarksOfRoom();
    """
  end

  def delete_message(message_id, socket) do
    delete socket, "li.message#" <> message_id
  end

  def set_inputbox_buttons(socket, mode) when mode in [true, :active] do
    async_js socket, """
      $('.message-buttons').hide();
      $('.message-buttons.send-button').show();
      $('#{@message_box}').addClass('dirty');
      """
  end

  def set_inputbox_buttons(socket, mode) when mode in [false, nil, :empty] do
    async_js socket, """
      $('.message-buttons').show();
      $('.message-buttons.send-button').hide();
      $('#{@message_box}').removeClass('dirty');
      """
  end

  def desktop_notify(socket, opts) do
    message = opts.message
    title =
      if message.channel.type == 2 do
        ~s/"New Direct Message"/
      else
        ~s/"New Message in ##{opts.channel_name}"/
      end
    subtitle = ~s/"From @#{opts.username}"/
    body = Poison.encode! opts.body
    id = inspect message.id
    channel_id = inspect message.channel_id
    channel_name = inspect message.channel.name
    # icon = OneChatWeb.Router.Helpers.home_url(InfinityOneWeb.Endpoint, :index) <>
    #   String.trim_leading(opts.icon, "/")

    async_js socket, """
      OneChat.notifier.desktop(#{title}, #{body}, {
        duration: #{opts.duration},
        channel_id: #{channel_id},
        subtitle: #{subtitle},
        icon: '#{opts.icon}',
        onclick: function(event) {
          OneChat.userchan.push("notification:click",
            {message_id: #{id}, name: '#{opts.username}', channel_id: #{channel_id}, channel_name: #{channel_name}});
        }
      });
      OneChat.roomManager.set_badges();
      """
      |> String.replace("\n", "")
    socket
  end

  def notify_audio(socket, sound) do
    async_js socket, ~s/OneChat.notifier.audio('#{sound}')/
    socket
  end

  def close_flex_bar(socket) do
    Query.delete socket, class: "opened", from: "#flex-tabs.opened"
    # async_js socket, "$('#flex-tabs"
  end

  defdelegate broadcast!(socket, event, bindings), to: Phoenix.Channel
  defdelegate render_to_string(view, templ, bindings), to: Phoenix.View
  defdelegate insert_html(socket, selector, position, html), to: Rebel.Element
  defdelegate toastr!(socket, which, message), to: OneChatWeb.RebelChannel.Client
  defdelegate toastr(socket, which, message), to: OneChatWeb.RebelChannel.Client
  defdelegate broadcast_js(socket, js), to: Rebel.Core
  defdelegate async_js(socket, js), to: Rebel.Core
end
