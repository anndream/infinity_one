defmodule InfinityOne.TabBar do
  @moduledoc """
  Manage the TabBar data store.

  Manages the the data store for buttons and ftab state.
  """
  @name :tabbar

  @doc """
  Initialize the TabBar data store.
  """
  def initialize do
    :ets.new @name, [:public, :named_table]
  end

  @doc """
  Insert an entry into the data store
  """
  def insert(key, value) do
    :ets.insert @name, {key, value}
  end

  @doc """
  Lookup a value from the data store
  """
  def lookup(key) do
    :ets.lookup @name, key
  end

  @doc """
  Add a button to the button store

  ## Examples

      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1"}
      true
  """
  def add_button(config) do
    insert {:button, config.id}, config
  end

  @doc """
  Get a button from the button store

  ## Examples

      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1"}
      iex> InfinityOne.TabBar.get_button "one"
      %{id: "one", name: "B1"}
  """
  def get_button(key) do
    case lookup {:button, key} do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc """
  Get a button from the button store

  ## Examples

      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1"}
      iex> InfinityOne.TabBar.get_button! "one"
      %{id: "one", name: "B1"}
  """
  def get_button!(key) do
    get_button(key) || raise("invalid button #{key}")
  end

  @doc """
  Get all buttons from the button store

  ## Examples

      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1", display: true}
      iex> InfinityOne.TabBar.get_buttons
      [%{id: "one", name: "B1", display: true}]
  """
  def get_buttons() do
    @name
    |> :ets.match({{:button, :"_"}, :"$2"})
    |> List.flatten
    |> Enum.filter(& &1.display)
    |> Enum.sort(& &1.order < &2.order)
  end

  def update_button(key, field, value) do
    button = get_button(key)
    add_button Map.put(button, field, value)
  end

  def show_button(key) do
    update_button key, :display, true
  end

  def hide_button(key) do
    update_button key, :display, false
  end

  @doc """
  Add a ftab from the ftab store

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      true
  """
  def open_ftab(user_id, channel_id, name, nil) do
    if view = get_view user_id, channel_id, name do
      insert {:ftab, {user_id, channel_id}}, {name, view}
    else
      insert {:ftab, {user_id, channel_id}}, {name, nil}
    end
  end

  def open_ftab(user_id, channel_id, name, view) do
    insert {:ftab, {user_id, channel_id}}, {name, view}
    open_view user_id, channel_id, name, view
  end

  @doc """
  Get a ftab from the ftab store

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.get_ftab 1, 2
      {"test", nil}

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", %{one: 1}
      iex> InfinityOne.TabBar.get_ftab 1, 2
      {"test", %{one: 1}}
  """
  def get_ftab(user_id, channel_id) do
    case lookup {:ftab, {user_id, channel_id}} do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc """
  Get the open view from the ftab store.

  ## Examples

      iex> InfinityOne.TabBar.insert {:ftab_view, {1, 2, "test"}}, %{one: 1}
      iex> InfinityOne.TabBar.get_view 1, 2, "test"
      %{one: 1}
  """
  def get_view(user_id, channel_id, name) do
    case lookup {:ftab_view, {user_id, channel_id, name}} do
      [{_, data}] -> data
      _ -> nil
    end
  end

  @doc """
  Inserts a ftab view into the store.

  ## Examples

      iex> InfinityOne.TabBar.open_view 1, 2, "other", %{two: 2}
      iex> InfinityOne.TabBar.get_view 1, 2, "other"
      %{two: 2}
  """
  def open_view(user_id, channel_id, name, view) do
    insert {:ftab_view, {user_id, channel_id, name}}, view
  end

  @doc """
  Removes a ftab view from the store.

  ## Examples

      iex> InfinityOne.TabBar.open_view 1, 2, "other", %{two: 2}
      iex> InfinityOne.TabBar.close_view 1, 2, "other"
      iex> InfinityOne.TabBar.get_view 1, 2, "other"
      nil
  """
  def close_view(user_id, channel_id, name) do
    :ets.delete @name, {:ftab_view, {user_id, channel_id, name}}
    insert {:ftab, {user_id, channel_id}}, {name, nil}
  end

  @doc """
  Close a ftab

  Removes the ftab entry

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.get_ftab 1, 2
      {"test", nil}
      iex> InfinityOne.TabBar.close_ftab 1, 2
      iex> InfinityOne.TabBar.get_ftab 1, 2
      nil

  """
  def close_ftab(user_id, channel_id) do
    :ets.delete @name, {:ftab, {user_id, channel_id}}
  end

  @doc """
  Get all ftabs

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> InfinityOne.TabBar.get_ftabs |> Enum.sort
      [[{1, 2}, {"test", nil}], [{1, 3}, {"other", %{one: 1}}]]

  """
  def get_ftabs() do
    :ets.match(@name, {{:ftab, :"$1"}, :"$2"})
  end

  @doc """
  Get all views

  ## Examples
  """
  def get_views() do
    :ets.match(@name, {{:ftab_view, :"$1"}, :"$2"})
  end

  @doc """
  Get all tabs for a given user.

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> InfinityOne.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> InfinityOne.TabBar.get_ftabs(1) |> Enum.sort
      [{"other", %{one: 1}}, {"test", nil}]
  """
  def get_ftabs(user_id) do
    @name
    |> :ets.match({{:ftab, {user_id, :"_"}}, :"$2"})
    |> List.flatten
  end

  @doc """
  Get all views for a given user
  """
  def get_views(user_id) do
    @name
    |> :ets.match({{:ftab_view, {user_id, :"_", :"$1"}}, :"$2"})
    |> List.flatten
  end

  @doc """
  Close all ftabs for a given user.

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> InfinityOne.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> InfinityOne.TabBar.close_user_ftabs 1
      iex> InfinityOne.TabBar.get_ftabs
      [[{2, 3}, {"other", %{one: 2}}]]

  """
  def close_user_ftabs(user_id) do
    :ets.match_delete @name, {{:ftab, {user_id, :"_"}}, :"_"}
  end

  @doc """
  Close all ftabs for a given channel.

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> InfinityOne.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> InfinityOne.TabBar.close_channel_ftabs 3
      iex> InfinityOne.TabBar.get_ftabs
      [[{1, 2}, {"test", nil}]]

  """
  def close_channel_ftabs(channel_id) do
    :ets.match_delete @name, {{:ftab, {:"_", channel_id}}, :"_"}
  end

  @doc """
  Delete all ftabs

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.open_ftab 1, 3, "other", %{one: 1}
      iex> InfinityOne.TabBar.open_ftab 2, 3, "other", %{one: 2}
      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1", display: true}
      iex> InfinityOne.TabBar.delete_ftabs
      iex> InfinityOne.TabBar.get_ftabs
      []
      iex> InfinityOne.TabBar.get_buttons
      [%{id: "one", name: "B1", display: true}]
  """
  def delete_ftabs do
    :ets.match_delete(@name, {{:ftab, :"_"}, :"_"})
  end

  @doc """
  Delete all ftabs

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1"}
      iex> InfinityOne.TabBar.add_button %{id: "two", name: "B2"}
      iex> InfinityOne.TabBar.delete_buttons
      iex> InfinityOne.TabBar.get_buttons
      []
      iex> InfinityOne.TabBar.get_ftabs
      [[{1, 2}, {"test", nil}]]
  """
  def delete_buttons do
    :ets.match_delete(@name, {{:button, :"_"}, :"_"})
  end

  @doc """
  Get all entries

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1"}
      iex> InfinityOne.TabBar.add_button %{id: "two", name: "B2"}
      iex> InfinityOne.TabBar.get_all |> Enum.sort
      [[{{:button, "one"}, %{id: "one", name: "B1"}}],
      [{{:button, "two"}, %{id: "two", name: "B2"}}],
      [{{:ftab, {1, 2}}, {"test", nil}}]]
  """
  def get_all do
    :ets.match @name, :"$1"
  end

  @doc """
  Delete all entries

  ## Examples

      iex> InfinityOne.TabBar.open_ftab 1, 2, "test", nil
      iex> InfinityOne.TabBar.add_button %{id: "one", name: "B1"}
      iex> InfinityOne.TabBar.add_button %{id: "two", name: "B2"}
      iex> InfinityOne.TabBar.delete_all
      iex> InfinityOne.TabBar.get_all
      []
  """
  def delete_all do
    :ets.match_delete @name, :"$1"
  end


end
