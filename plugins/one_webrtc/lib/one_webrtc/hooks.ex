defmodule OneWebrtc.Hooks do
  use Unbrella.Hooks, :add_hooks

  add_hook :add_flex_buttons, [] do
    OneWebrtcWeb.FlexBar.Tab.Webrtc.add_buttons
  end

  add_hook :register_admin_pages, OneWebrtcWeb.Admin, :add_pages
end
