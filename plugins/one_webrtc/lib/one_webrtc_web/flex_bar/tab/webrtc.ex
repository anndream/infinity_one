defmodule OneWebrtcWeb.FlexBar.Tab.Webrtc do
  use OneChatWeb.FlexBar.Helpers
  alias InfinityOne.OnePubSub

  alias InfinityOne.{TabBar.Tab, Repo}
  alias OneWebrtcWeb.{FlexBar.Tab.MembersList, FlexBarView}
  alias OneWebrtc.ClientDevice

  require Logger

  @spec add_buttons() :: any
  def add_buttons do
    TabBar.add_button Tab.new(
      __MODULE__,
      ~w[channel group direct im],
      "device-settings",
      ~g"Device Settings",
      "icon-mic",
      FlexBarView,
      "device.html",
      95,
      [
        model: OneWebrtc.ClientDevice,
        prefix: "client_device"
      ])

    TabBar.add_button Tab.new(
      MembersList,
      "webrtc-members-list")
  end

  @spec args(socket, {id, id, any, map}, args) :: {List.t, socket}
  def args(socket, {user_id, _channel_id, _, _}, _) do
    # Logger.error "assigns: #{inspect socket.assigns}"
    current_user = Helpers.get_user! user_id
    client_device = ClientDevice.get_by(user_id: current_user.id, ip_addr: socket.assigns.ip_address) ||
    # client_device = ClientDevice.get_by(user_id: current_user.id) ||
      ClientDevice.new()

    changeset = ClientDevice.change client_device, %{user_id: current_user.id}

    assigns =
      socket
      |> Rebel.get_assigns()
      |> Map.put(:client_device, client_device)
      |> Map.put(:resource_key, :client_device)

    Rebel.put_assigns(socket, assigns)

    {[
      client_device: client_device,
      changeset: changeset,
      devices: get_client_devices(socket),
    ], socket}
  end

  defp get_client_devices(socket) do
    socket
    |> exec_js("window.InfinityOne.installed_devices")
    # |> IO.inspect(label: "installed_devices")
    |> case do
      {:ok, devices} -> devices
      {:error, nil}  -> nil
    end
    |> build_client_devices
  end

  defp build_client_devices(nil), do: %{}
  defp build_client_devices(devices) do
    devices
    # |> IO.inspect(label: "installed_devices")
    |> Enum.reduce(%{input: [], output: [], video: []}, fn
      %{"kind" => "audioinput", "id" => id, "label" => label}, acc ->
        update_in acc, [:input], &([{label, id} | &1])
      %{"kind" => "audiooutput", "id" => id, "label" => label}, acc ->
        update_in acc, [:output], &([{label, id} | &1])
      %{"kind" => "videoinput", "id" => id, "label" => label}, acc ->
        update_in acc, [:video], &([{label, id} | &1])
    end)
    |> update_in([:input], &Enum.reverse/1)
    |> update_in([:output], &Enum.reverse/1)
    |> update_in([:video], &Enum.reverse/1)
  end

  def flex_form_select_change(socket, sender, resource, field, _value) do
    user_id = socket.assigns.user_id

    resource
    |> ClientDevice.change(%{field => sender["value"], "user_id" => user_id})
    |> Repo.insert_or_update
    |> case do
      {:ok, device} ->
        OnePubSub.broadcast "user:" <> user_id, "device:change", %{device: device}
        {:ok, socket}
      {:error, changeset} ->
        {:error, changeset, socket}
    end
  end
end
