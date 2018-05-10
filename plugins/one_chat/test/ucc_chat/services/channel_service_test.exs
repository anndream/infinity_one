defmodule OneChat.ChannelServiceTest do
  use OneChat.DataCase

  import OneChat.TestHelpers

  alias OneChat.ChannelService, as: Service
  alias InfinityOne.{Permissions}

  setup do
    InfinityOne.TestHelpers.insert_roles()
    Permissions.initialize_permissions_db()
    Permissions.initialize(Permissions.list_permissions())

    user = InfinityOne.TestHelpers.insert_user()

    channel = insert_channel(user)
    OneSettings.init_all()
    {:ok, %{user: user, channel: channel}}
  end

  # test "create_subscription", %{user: user, channel: channel} do
  #   {:ok, sub} = Service.create_subscription channel, user.id
  #   assert sub.type == 0

  #   user2 = InfinityOne.TestHelpers.insert_user
  #   {:ok, sub} = Service.create_subscription channel.id, user2.id
  #   assert sub.user_id == user2.id
  # end

  test "invite_user", %{user: user, channel: channel} do
    user2 = InfinityOne.TestHelpers.insert_user
    {:ok, _result} = Service.invite_user user, channel.id, user2.id, channel: false
    [sub] = OneChat.Subscription.list
    assert sub.user_id == user.id
  end

  test "join_channel channel", %{user: user, channel: channel} do
    Service.join_channel channel, user.id, channel: false
    [sub] = OneChat.Subscription.list
    assert sub.user_id == user.id
    assert sub.channel_id == channel.id
  end

  test "join_channel channel_id", %{user: user, channel: channel} do
    Service.join_channel channel.id, user.id, channel: false
    [sub] = OneChat.Subscription.list
    assert sub.user_id == user.id
    assert sub.channel_id == channel.id
  end

  test "set_subscription_state", %{user: user, channel: channel} do
    Service.join_channel channel, user.id, channel: false
    Service.set_subscription_state channel.id, user.id, true
    [sub] = OneChat.Subscription.list
    assert sub.open
    Service.set_subscription_state channel.id, user.id, false
    [sub] = OneChat.Subscription.list
    refute sub.open
  end

  test "set_subscription_state_room", %{user: user, channel: channel} do
    Service.join_channel channel, user.id, channel: false
    Service.set_subscription_state_room channel.name, user.id, true
    [sub] = OneChat.Subscription.list
    assert sub.open
    Service.set_subscription_state_room channel.name, user.id, false
    [sub] = OneChat.Subscription.list
    refute sub.open
  end

end
