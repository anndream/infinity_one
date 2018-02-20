alias UcxUcc.Repo
alias UcxUcc.{Accounts, Permissions}
alias Accounts.{User, Role, UserRole, Account, PhoneNumber, PhoneNumberLabel}
alias Permissions.{Permission, PermissionRole}
alias UccChat.{ChannelService, Subscription, Message, Channel}
alias UcxPresence.Extension
# alias Mscs.{Client, Apb}

# Extension.delete_all
Message.delete_all
Subscription.delete_all
Channel.delete_all

Repo.delete_all PhoneNumberLabel
Repo.delete_all PhoneNumber
Repo.delete_all PermissionRole
Repo.delete_all UserRole
Repo.delete_all Permission
Repo.delete_all Role
Repo.delete_all Account
Repo.delete_all User

IO.puts "Creating Roles"
roles =
  UcxUcc.Accounts.Role.default_roles()
  |> Enum.map(fn {role, scope} ->
    %{name: to_string(role), scope: to_string(scope)}
    |> Accounts.create_role()
    |> elem(1)
  end)
  |> Enum.map(fn %{name: name, id: id} -> {to_string(name), id} end)
  |> Enum.into(%{})

create_username = fn name ->
  name
  |> String.downcase
  |> String.split(" ", trim: true)
  |> hd
  # |> Enum.join(".")
end

create_user = fn name, email, password, admin ->
  username = create_username.(name)
  params = %{
    username: username, name: name, email: email,
    password: password, password_confirmation: password
  }
  params = if admin == :bot, do: Map.put(params, :avatar_url, "/images/hubot.png"), else: params
  user =
    %User{}
    |> User.changeset(params)
    |> Repo.insert!
    |> Repo.preload([:phone_numbers])

  Coherence.Controller.confirm! user

  role_id = case admin do
    true -> roles["admin"]
    false -> roles["user"]
    :bot -> roles["bot"]
  end

  Accounts.create_user_role(%{user_id: user.id, role_id: role_id})
  Accounts.create_account(%{user_id: user.id})
  Accounts.get_user user.id, default_preload: true
end

insert_channel! = fn params ->
  ch = Channel.create! params
  {:ok, _} = Accounts.create_user_role %{user_id: ch.user_id, role_id: roles["owner"]}
  ch
end

IO.puts "Creating Permissions"
# build the permissions
roles_list = roles

Repo.delete_all UcxUcc.Permissions.Permission

UcxUcc.Permissions.default_permissions()
|> Enum.each(fn %{name: name, roles: roles} ->
  {:ok, permission} = Permissions.create_permission(%{name: name})
  roles
  |> Enum.each(fn role_name ->
    Permissions.create_permission_role(%{permission_id: permission.id, role_id: roles_list[role_name]})
  end)
end)

IO.puts "Creating First Users"
# build the users
_u0 = create_user.("Bot", "bot@example.com", "test", :bot)
u1 = create_user.("Admin", "admin@spallen.com", "test", true)
u2 = create_user.("Steve Pallen", "steve.pallen@spallen.com", "test", true)
u3 = create_user.("Merilee Lackey", "merilee.lackey@spallen.com", "test", false)

# TODO: The following should be moved to the UccChat seeds.exs file

IO.puts "Creating Second Users"
users =
  [
    "Jamie Pallen", "Jason Pallen", "Simon", "Eric", "Lina", "Denine", "Vince", "Richard", "Sharron",
    "Ardavan", "Joseph", "Chris", "Osmond", "Patrick", "Tom", "Jeff"
  ]
  |> Enum.map(fn name ->
    lname = create_username.(name)
    create_user.(name, "#{lname}@example.com", "test", false)
  end)

IO.puts "Creating Channels"

ch1 = insert_channel!.(%{name: "general", user_id: u1.id, default: true})
ch2 = insert_channel!.(%{name: "support", user_id: u2.id})

channels =
  ~w(Research Marketing HR Accounting Shipping Sales) ++ ["UCxWebUser", "UCxChat", "BigRoom"]
  |> Enum.map(fn name ->
    insert_channel!.(%{name: name, user_id: u1.id})
  end)

IO.puts "Creating Subscriptions"

[ch1, ch2] ++ Enum.take(channels, 3)
|> Enum.each(fn ch ->
  Subscription.create!(%{channel_id: ch.id, user_id: u1.id})
  Subscription.create!(%{channel_id: ch.id, user_id: u2.id})
  Subscription.create!(%{channel_id: ch.id, user_id: u3.id})
end)

users
|> Enum.each(fn c ->
  Subscription.create!(%{channel_id: ch1.id, user_id: c.id})
end)

IO.puts "Creating more Channels"

chan_parts = ~w(biz sales tech foo home work product pbx phone iphone galaxy android slim user small big sand storm snow rain tv shows earth hail)
for i <- 1..50 do
  name = Enum.random(chan_parts) <> to_string(i) <> Enum.random(chan_parts)
  user = Enum.random(users)
  insert_channel!.(%{name: name, user_id: user.id})
end

add_messages = true

IO.puts "Creating Messages"

if add_messages do
  messages = [
    "hello there",
    "what's up doc",
    "are you there?",
    "Did you get the join?",
    "When will you be home?",
    "Be right there!",
    "Can't wait to see you!",
    "What did you watch last night?",
    "Is your homework done yet?",
    "what time is it?",
    "whats for dinner?",
    "are you sleeping?",
    "how did you sleep last night?",
    "did you have a good trip?",
    "Tell me about your day",
    "be home by 5 please",
    "wake me up a 9 please",
    "ttyl",
    "cul8r",
    "hope it works",
    "Let me tell you a story about a man named Jed",
  ]

  user_ids = [u1.id, u2.id, u3.id]
  other_ch_ids = Enum.take(channels, 3) |> Enum.map(&(&1.id))
  num_messages = 20 # 500
  for _ <- 0..num_messages do
    for ch_id <- [ch1.id, ch2.id] ++ other_ch_ids do
      id = Enum.random user_ids
      Message.create!(%{channel_id: ch_id, user_id: id, body: Enum.random(messages)})
    end
  end

  for _ <- 0..num_messages do
    id = Enum.random user_ids
    Message.create!(%{channel_id: ch1.id, user_id: id, body: Enum.random(messages)})
  end

  new_channel_users = [
    {Enum.random(users), Enum.random(channels)},
    {Enum.random(users), Enum.random(channels)},
    {Enum.random(users), Enum.random(channels)},
    {Enum.random(users), Enum.random(channels)},
    {Enum.random(users), Enum.random(channels)},
    {Enum.random(users), Enum.random(channels)},
    {Enum.random(users), Enum.random(channels)},
  ]

  IO.puts "Creating More Subscriptions"

  new_channel_users
  |> Enum.each(fn {c, ch} ->
    Subscription.create!(%{channel_id: ch.id, user_id: c.id})
  end)

  for _ <- 1..num_messages do
    {c, ch} = Enum.random new_channel_users
    Message.create!(%{channel_id: ch.id, user_id: c.id, body: Enum.random(messages)})
  end
end

IO.puts "Creating Settings"

UccSettings.init_all()

IO.puts "Setting phone number labels"

[_work, _home, _mobile] =
  ~w(Work Home Mobile)
  |> Enum.map(fn label ->
      Accounts.create_phone_number_label! %{name: label}
  end)

