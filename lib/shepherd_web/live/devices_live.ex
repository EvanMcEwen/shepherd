defmodule ShepherdWeb.DevicesLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Devices")
     |> assign(:devices, mock_devices())
     |> assign(:filter, "all")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:devices} page_title="Devices">
      <%!-- Header --%>
      <div class="flex items-center justify-between mb-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-bold text-slate-900 dark:text-white">Devices</h2>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Manage and monitor your device fleet</p>
        </div>
        <button class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg shadow-sm transition-colors">
          <.icon name="hero-plus" class="size-4" />
          Register Device
        </button>
      </div>

      <%!-- Filters --%>
      <div class="flex items-center gap-2 mb-5 animate-fade-in delay-75">
        <button
          :for={filter <- ["all", "online", "offline", "updating"]}
          class={[
            "px-3 py-1.5 text-xs font-medium rounded-lg transition-colors",
            if(@filter == filter,
              do: "bg-slate-900 dark:bg-white text-white dark:text-slate-900",
              else: "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
            )
          ]}
          phx-click="filter"
          phx-value-filter={filter}
        >
          {String.capitalize(filter)}
        </button>
      </div>

      <%!-- Devices table --%>
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden animate-fade-in-up delay-150">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-slate-100 dark:border-slate-800">
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Device</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Status</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Group</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Firmware</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Last Seen</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
              <tr :for={device <- @devices} class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                <td class="px-6 py-4">
                  <div>
                    <p class="text-sm font-medium text-slate-900 dark:text-white">{device.nickname || device.serial}</p>
                    <p class="text-xs text-slate-500 font-mono">{device.serial}</p>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span class={[
                    "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium",
                    status_classes(device.status)
                  ]}>
                    <span class={[
                      "w-1.5 h-1.5 rounded-full",
                      if(device.status == :online, do: "bg-emerald-500 animate-pulse-dot", else: "bg-current opacity-40")
                    ]}></span>
                    {status_label(device.status)}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-slate-600 dark:text-slate-300">{device.group || "—"}</td>
                <td class="px-6 py-4">
                  <span class="text-sm font-mono text-slate-600 dark:text-slate-300">{device.firmware}</span>
                </td>
                <td class="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">{device.last_seen}</td>
                <td class="px-6 py-4 text-right">
                  <.link navigate={~p"/devices/#{device.id}"} class="text-sm font-medium text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 transition-colors">
                    View
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  defp status_classes(:online), do: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400"
  defp status_classes(:offline), do: "bg-slate-100 dark:bg-slate-500/10 text-slate-600 dark:text-slate-400"
  defp status_classes(:updating), do: "bg-blue-50 dark:bg-blue-500/10 text-blue-700 dark:text-blue-400"
  defp status_classes(_), do: "bg-slate-100 text-slate-600"

  defp status_label(:online), do: "Online"
  defp status_label(:offline), do: "Offline"
  defp status_label(:updating), do: "Updating"
  defp status_label(_), do: "Unknown"

  defp mock_devices do
    [
      %{id: 1, serial: "SHP-001-A7F3", nickname: "Gateway Alpha", status: :online, firmware: "v2.4.1", group: "Production", last_seen: "Just now"},
      %{id: 2, serial: "SHP-002-B8E4", nickname: "Sensor Hub 1", status: :online, firmware: "v2.4.1", group: "Production", last_seen: "1 min ago"},
      %{id: 3, serial: "SHP-003-C9D5", nickname: "Edge Node 3", status: :offline, firmware: "v2.3.0", group: "Staging", last_seen: "18 min ago"},
      %{id: 4, serial: "SHP-004-D0F6", nickname: nil, status: :updating, firmware: "v2.4.0", group: "Development", last_seen: "Just now"},
      %{id: 5, serial: "SHP-005-E1A7", nickname: "Relay Beta", status: :offline, firmware: "v2.2.1", group: nil, last_seen: "2 hours ago"},
      %{id: 6, serial: "SHP-006-F2B8", nickname: "Gateway Gamma", status: :online, firmware: "v2.4.1", group: "Production", last_seen: "Just now"},
      %{id: 7, serial: "SHP-007-G3C9", nickname: "Sensor Hub 2", status: :offline, firmware: "v2.3.0", group: "Staging", last_seen: "45 min ago"},
      %{id: 8, serial: "SHP-008-H4D0", nickname: nil, status: :online, firmware: "v2.4.1", group: "Production", last_seen: "3 min ago"}
    ]
  end
end
