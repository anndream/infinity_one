defmodule InfinityOne.TabBar.Ftab do

  alias InfinityOne.TabBar

  require Logger

  @type id :: String.t


  @doc """
  Check if any tab is open.

  ## Examples

      iex> InfinityOne.TabBar.Ftab.open? 1, 1
      iex> false
      iex> InfinityOne.TabBar.open_ftab 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.open? 1, 1
      true
  """
  @spec open?(id, id) :: boolean
  def open?(user_id, channel_id) do
    !!get(user_id, channel_id)
  end

  @doc """
  Check if a given tab is open.

  ## Examples

      iex> InfinityOne.TabBar.Ftab.open? 1, 1
      iex> false
      iex> InfinityOne.TabBar.Ftab.open 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.open? 1, 1, "test"
      true
      iex> InfinityOne.TabBar.Ftab.open? 1, 1, "other"
      false
  """
  @spec open?(id, id, String.t) :: boolean
  def open?(user_id, channel_id, name) do
    case get(user_id, channel_id) do
      {^name, _} -> true
      _ -> false
    end
  end

  @doc """
  Toggle a given tab.

  If the tab is open, close it. Otherwise open it.

  ## Examples

      iex> InfinityOne.TabBar.Ftab.toggle 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.open? 1, 1, "test"
      true
      iex> InfinityOne.TabBar.Ftab.toggle 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.open? 1, 1, "test"
      false

      iex> InfinityOne.TabBar.Ftab.toggle 1, 2, "other", nil, &(send self(), {&1, &2})
      iex> InfinityOne.TabBar.Ftab.open? 1, 2, "other"
      true
      iex> receive do
      ...> {:open, {"other", nil}} -> true
      ...> _ -> false
      ...> end
      true
  """
  @spec toggle(id, id, String.t, Map.t | nil, function | nil) :: any
  def toggle(user_id, channel_id, name, view, callback \\ nil) do
    if open? user_id, channel_id, name do
      close user_id, channel_id, callback
    else
      open user_id, channel_id, name, view, callback
    end
  end

  @doc """
  Open a tab.

  ## Examples

      iex> InfinityOne.TabBar.Ftab.open? 1, 1, "test"
      false
      iex> InfinityOne.TabBar.Ftab.open 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.open? 1, 1, "test"
      true
  """
  def open(user_id, channel_id, name, view, callback \\ nil) do
    TabBar.open_ftab user_id, channel_id, name, view
    view = TabBar.get_view user_id, channel_id, name
    if callback, do: callback.(:open, {name, view})
  end

  @doc """
  Close a tab.

  ## Examples

      iex> InfinityOne.TabBar.Ftab.open 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.close 1, 1
      iex> InfinityOne.TabBar.Ftab.open? 1, 1
      false

      iex> InfinityOne.TabBar.Ftab.open 1, 1, "test", %{one: 1}
      iex> InfinityOne.TabBar.Ftab.close 1, 1, &(send self(), {&1, &2})
      iex> InfinityOne.TabBar.Ftab.open? 1, 1
      false
      iex> receive do
      ...> {:close, nil} -> true
      ...> end
      true
  """
  def close(user_id, channel_id, callback \\ nil) do
    TabBar.close_ftab user_id, channel_id
    if callback, do: callback.(:close, nil)
  end

  @doc """
  Get an open tab entry

  ## Examples

      iex> InfinityOne.TabBar.Ftab.get 1, 1
      nil
      iex> InfinityOne.TabBar.Ftab.open 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.get 1, 1
      {"test", nil}
  """
  def get(user_id, channel_id) do
    TabBar.get_ftab(user_id, channel_id)
  end

  @doc """
  Reopen a tab.

  Used on a room change. Checks to see if the tab was open. If so,
  the tab is opened again.

  ## Examples

      iex> InfinityOne.TabBar.Ftab.open 1, 1, "test", nil
      iex> InfinityOne.TabBar.Ftab.reload 1, 1, &(send self(), {&1, &2})
      iex> receive do
      ...> {:open, {"test", nil}} -> true
      ...> _ -> false
      ...> end
      true
      iex> InfinityOne.TabBar.Ftab.reload 1, 2, &(send self(), {&1, &2})
      iex> receive do
      ...> {:ok, nil} -> :pass
      ...> other -> other
      ...> end
      :pass
  """
  def reload(user_id, channel_id, callback \\ nil) do
    case get user_id, channel_id do
      {name, args} ->
        open user_id, channel_id, name, args, callback
      nil ->
        if callback, do: callback.(:ok, nil)
    end
  end

  def close_view(user_id, channel_id, name, callback \\ nil) do
    case TabBar.get_view user_id, channel_id, name do
      nil ->
        if callback, do: callback.({:ok, nil})
      _view ->
        if callback, do: callback.({:open, {name, nil}})
    end
  end
end
