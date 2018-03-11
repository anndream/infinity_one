defmodule OneChatWeb.FlexBar.Tab.ImMode do
  use OneChatWeb.FlexBar.Helpers

  alias InfinityOne.TabBar.Tab

  @spec add_buttons() :: any
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel group direct],
      "im-mode",
      ~g"IM Mode",
      "icon-menu",
      # "icon-chat",
      View,
      "",
      1)
  end
end

