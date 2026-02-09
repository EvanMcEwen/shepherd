defmodule ShepherdWeb.DeviceDetailLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    device = mock_device(id)

    {:ok,
     socket
     |> assign(:page_title, device.nickname || device.serial)
     |> assign(:device, device)
     |> assign(:metrics, mock_metrics())
     |> assign(:update_history, mock_update_history())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:devices} page_title={@device.nickname || @device.serial}>
      <%!-- Breadcrumb --%>
      <nav class="flex items-center gap-2 text-sm text-slate-500 mb-6 animate-fade-in">
        <.link navigate={~p"/devices"} class="hover:text-slate-700 dark:hover:text-slate-300 transition-colors">Devices</.link>
        <.icon name="hero-chevron-right-micro" class="size-4" />
        <span class="text-slate-900 dark:text-white font-medium">{@device.nickname || @device.serial}</span>
      </nav>

      <%!-- Device header --%>
      <div class="flex items-start justify-between mb-8 animate-fade-in delay-75">
        <div class="flex items-center gap-4">
          <div class={[
            "flex items-center justify-center w-14 h-14 rounded-xl",
            if(@device.status == :online, do: "bg-emerald-500/10", else: "bg-slate-100 dark:bg-slate-800")
          ]}>
            <.icon name="hero-cpu-chip" class={[
              "size-7",
              if(@device.status == :online, do: "text-emerald-500", else: "text-slate-400")
            ]} />
          </div>
          <div>
            <h2 class="text-xl font-bold text-slate-900 dark:text-white">{@device.nickname || @device.serial}</h2>
            <p class="text-sm text-slate-500 font-mono">{@device.serial}</p>
            <div class="flex items-center gap-3 mt-1.5">
              <span class={[
                "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium",
                if(@device.status == :online,
                  do: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
                  else: "bg-slate-100 dark:bg-slate-500/10 text-slate-600 dark:text-slate-400"
                )
              ]}>
                <span class={[
                  "w-1.5 h-1.5 rounded-full",
                  if(@device.status == :online, do: "bg-emerald-500 animate-pulse-dot", else: "bg-slate-400")
                ]}></span>
                {if(@device.status == :online, do: "Online", else: "Offline")}
              </span>
              <span class="text-xs text-slate-400">Last seen: {@device.last_seen}</span>
            </div>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button class="px-3 py-2 text-sm font-medium text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
            <.icon name="hero-pencil-square" class="size-4" />
          </button>
          <button class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg shadow-sm transition-colors">
            <.icon name="hero-rocket-launch" class="size-4" />
            Deploy Update
          </button>
        </div>
      </div>

      <%!-- Info grid --%>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <%!-- Device info --%>
        <div class="lg:col-span-2 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 animate-fade-in-up delay-150">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white mb-4">Device Information</h3>
          <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-8 gap-y-4">
            <div>
              <dt class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Serial</dt>
              <dd class="mt-1 text-sm font-mono text-slate-900 dark:text-white">{@device.serial}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Nickname</dt>
              <dd class="mt-1 text-sm text-slate-900 dark:text-white">{@device.nickname || "—"}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Firmware</dt>
              <dd class="mt-1 text-sm font-mono text-slate-900 dark:text-white">{@device.firmware}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Target</dt>
              <dd class="mt-1 text-sm text-slate-900 dark:text-white">{@device.target}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Group</dt>
              <dd class="mt-1 text-sm text-slate-900 dark:text-white">{@device.group || "Unassigned"}</dd>
            </div>
            <div>
              <dt class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Cert Expires</dt>
              <dd class="mt-1 text-sm text-slate-900 dark:text-white">{@device.cert_expires}</dd>
            </div>
          </dl>
        </div>

        <%!-- Metrics --%>
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 animate-fade-in-up delay-225">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white mb-4">Latest Metrics</h3>
          <div class="space-y-4">
            <div :for={metric <- @metrics}>
              <div class="flex items-center justify-between mb-1">
                <span class="text-xs font-medium text-slate-500 dark:text-slate-400">{metric.name}</span>
                <span class="text-sm font-semibold text-slate-900 dark:text-white">{metric.value}{metric.unit}</span>
              </div>
              <div class="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                <div class={["h-full rounded-full", metric.color]} style={"width: #{metric.percent}%"}></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Update history --%>
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 animate-fade-in-up delay-300">
        <div class="px-6 py-4 border-b border-slate-100 dark:border-slate-800">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Update History</h3>
        </div>
        <div class="divide-y divide-slate-100 dark:divide-slate-800">
          <div :for={update <- @update_history} class="flex items-center justify-between px-6 py-4">
            <div class="flex items-center gap-3">
              <div class={["flex items-center justify-center w-8 h-8 rounded-lg", update.icon_bg]}>
                <.icon name={update.icon} class={["size-4", update.icon_color]} />
              </div>
              <div>
                <p class="text-sm font-medium text-slate-900 dark:text-white">{update.version}</p>
                <p class="text-xs text-slate-500">{update.date}</p>
              </div>
            </div>
            <span class={["inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium", update.status_classes]}>
              {update.status}
            </span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp mock_device(_id) do
    %{
      id: 1,
      serial: "SHP-001-A7F3",
      nickname: "Gateway Alpha",
      status: :online,
      firmware: "v2.4.1",
      target: "rpi4",
      group: "Production",
      last_seen: "Just now",
      cert_expires: "Mar 15, 2027"
    }
  end

  defp mock_metrics do
    [
      %{name: "CPU Usage", value: "23", unit: "%", percent: 23, color: "bg-blue-500"},
      %{name: "Memory", value: "156", unit: "MB", percent: 61, color: "bg-violet-500"},
      %{name: "Disk", value: "2.1", unit: "GB", percent: 34, color: "bg-emerald-500"},
      %{name: "Temperature", value: "42", unit: "C", percent: 52, color: "bg-amber-500"}
    ]
  end

  defp mock_update_history do
    [
      %{version: "v2.4.1", date: "Feb 7, 2026", status: "Complete", status_classes: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400", icon: "hero-check-circle", icon_bg: "bg-emerald-500/10", icon_color: "text-emerald-500"},
      %{version: "v2.4.0", date: "Jan 23, 2026", status: "Complete", status_classes: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400", icon: "hero-check-circle", icon_bg: "bg-emerald-500/10", icon_color: "text-emerald-500"},
      %{version: "v2.3.0", date: "Dec 12, 2025", status: "Complete", status_classes: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400", icon: "hero-check-circle", icon_bg: "bg-emerald-500/10", icon_color: "text-emerald-500"}
    ]
  end
end
