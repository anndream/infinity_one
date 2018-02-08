defmodule UccChat.Settings do
  use UccSettings

  alias UccChat.Notification

  def get_desktop_notification_duration(user, channel) do
    cond do
      not enable_desktop_notifications() ->
        nil
      not user.account.enable_desktop_notifications ->
        nil
      not is_nil(user.account.desktop_notification_duration) ->
        user.account.desktop_notification_duration
      true ->
        case Notification.get_notification(user.account.id, channel.id) do
          nil ->
            desktop_notification_duration()
          %{settings: %{duration: nil}} ->
            desktop_notification_duration()
          %{settings: %{duration: duration}} ->
            duration
        end
    end
  end

  def notifications_settings(%{} = user, %{id: channel_id}) do
    notifications_settings(user, channel_id)
  end

  def notifications_settings(%{account: account}, channel_id) do
    with true <- enable_desktop_notifications(),
         true <- account.enable_desktop_notifications do
      account
      |> Notification.get_notification(channel_id)
      |> Map.get(:settings, %{})
    end
  end

  def desktop_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{desktop: mode} -> mode
      other -> other
    end
  end

  def email_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{email: mode} -> mode
      other -> other
    end
  end

  def mobile_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{mobile: mode} -> mode
      other -> other
    end
  end

  def unread_alert_notifications_mode(%{} = user, channel) do
    case notifications_settings(user, channel) do
      %{unread_alert: mode} -> mode
      other -> other
    end
  end

  def get_new_message_sound(user, channel_id) do
    default = get_system_new_message_sound()
    cond do
      user.account.new_message_notification == "none" ->
        nil
      user.account.new_message_notification != "system_default" ->
        user.account.new_message_notification
      true ->
        case Notification.get_notification(user.account.id, channel_id) do
          nil -> default
          %{settings: %{audio: "system_default"}} -> default
          %{settings: %{audio: "none"}} -> nil
          %{settings: %{audio: sound}} -> sound
        end
    end
  end

  def get_new_room_sound(user) do
    case user.account.new_room_notification do
      "none"           -> nil
      "system_default" -> get_system_new_room_sound()
      other            -> other
    end
  end

  def get_system_new_message_sound, do: "chime"

  def get_system_new_room_sound, do: "door"

  def get_system_message_sound, do: "none"

end
