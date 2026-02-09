defmodule ShepherdWeb.DashboardLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:stats, mock_stats())
     |> assign(:recent_devices, mock_recent_devices())
     |> assign(:recent_activity, mock_recent_activity())
     |> assign(:firmware_status, mock_firmware_status())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:dashboard} page_title="Dashboard">
      <%!-- Welcome header --%>
      <div class="mb-8 animate-fade-in">
        <h2 class="text-2xl font-bold text-slate-900 dark:text-white">Welcome back</h2>
        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
          Here's what's happening across your fleet.
        </p>
      </div>

      <%!-- Stats cards --%>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <.stat_card
          label="Total Devices"
          value={@stats.total_devices}
          change="+3 this week"
          change_type={:positive}
          icon="hero-cpu-chip"
          icon_bg="bg-blue-500/10"
          icon_color="text-blue-500"
          delay="delay-75"
        />
        <.stat_card
          label="Online Now"
          value={@stats.online_devices}
          change={"#{@stats.online_percent}% of fleet"}
          change_type={:neutral}
          icon="hero-signal"
          icon_bg="bg-emerald-500/10"
          icon_color="text-emerald-500"
          delay="delay-150"
        />
        <.stat_card
          label="Firmware Versions"
          value={@stats.firmware_versions}
          change="Latest: v2.4.1"
          change_type={:neutral}
          icon="hero-arrow-up-tray"
          icon_bg="bg-violet-500/10"
          icon_color="text-violet-500"
          delay="delay-225"
        />
        <.stat_card
          label="Active Deployments"
          value={@stats.active_deployments}
          change="2 in progress"
          change_type={:warning}
          icon="hero-rocket-launch"
          icon_bg="bg-amber-500/10"
          icon_color="text-amber-500"
          delay="delay-300"
        />
      </div>

      <%!-- Main content grid --%>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <%!-- Device status breakdown --%>
        <div class="lg:col-span-2 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 animate-fade-in-up delay-150">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Fleet Overview</h3>
              <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Device status across all groups</p>
            </div>
            <.link navigate={~p"/devices"} class="inline-flex items-center gap-1.5 text-xs font-medium text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 dark:hover:text-emerald-300 transition-colors">
              View all
              <.icon name="hero-arrow-right-micro" class="size-3.5" />
            </.link>
          </div>

          <%!-- Status bars --%>
          <div class="space-y-4">
            <.status_bar label="Online" count={47} total={156} color="bg-emerald-500" />
            <.status_bar label="Offline" count={98} total={156} color="bg-slate-400" />
            <.status_bar label="Updating" count={8} total={156} color="bg-blue-500" />
            <.status_bar label="Error" count={3} total={156} color="bg-rose-500" />
          </div>

          <%!-- Group summary --%>
          <div class="mt-6 pt-6 border-t border-slate-100 dark:border-slate-800">
            <h4 class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-3">Groups</h4>
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <.group_pill name="Production" count={84} color="bg-emerald-500" />
              <.group_pill name="Staging" count={32} color="bg-blue-500" />
              <.group_pill name="Development" count={24} color="bg-violet-500" />
              <.group_pill name="Unassigned" count={16} color="bg-slate-400" />
            </div>
          </div>
        </div>

        <%!-- Quick actions + firmware --%>
        <div class="space-y-6">
          <%!-- Quick actions --%>
          <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 animate-fade-in-up delay-225">
            <h3 class="text-sm font-semibold text-slate-900 dark:text-white mb-4">Quick Actions</h3>
            <div class="space-y-2">
              <button class="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-800 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors group">
                <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-blue-500/10 group-hover:bg-blue-500/20 transition-colors">
                  <.icon name="hero-rocket-launch" class="size-4 text-blue-500" />
                </div>
                Deploy Firmware
              </button>
              <button class="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-800 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors group">
                <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-emerald-500/10 group-hover:bg-emerald-500/20 transition-colors">
                  <.icon name="hero-plus" class="size-4 text-emerald-500" />
                </div>
                Register Device
              </button>
              <button class="w-full flex items-center gap-3 px-4 py-3 text-sm font-medium text-slate-700 dark:text-slate-300 bg-slate-50 dark:bg-slate-800 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition-colors group">
                <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-violet-500/10 group-hover:bg-violet-500/20 transition-colors">
                  <.icon name="hero-arrow-up-tray" class="size-4 text-violet-500" />
                </div>
                Upload Firmware
              </button>
            </div>
          </div>

          <%!-- Latest firmware --%>
          <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 animate-fade-in-up delay-300">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Latest Firmware</h3>
              <.link navigate={~p"/firmware"} class="text-xs font-medium text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 transition-colors">
                View all
              </.link>
            </div>
            <div class="space-y-3">
              <.firmware_item
                :for={fw <- @firmware_status}
                version={fw.version}
                target={fw.target}
                devices={fw.devices}
                uploaded={fw.uploaded}
              />
            </div>
          </div>
        </div>
      </div>

      <%!-- Recent activity table --%>
      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 animate-fade-in-up delay-375">
        <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 dark:border-slate-800">
          <div>
            <h3 class="text-sm font-semibold text-slate-900 dark:text-white">Recent Activity</h3>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">Latest events across your fleet</p>
          </div>
          <button class="text-xs font-medium text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 transition-colors">
            View all activity
          </button>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-slate-100 dark:border-slate-800">
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Event</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Device</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Status</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Time</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
              <tr :for={activity <- @recent_activity} class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                <td class="px-6 py-3.5">
                  <div class="flex items-center gap-2.5">
                    <div class={["flex items-center justify-center w-7 h-7 rounded-lg", activity.icon_bg]}>
                      <.icon name={activity.icon} class={["size-3.5", activity.icon_color]} />
                    </div>
                    <span class="text-sm font-medium text-slate-900 dark:text-slate-100">{activity.event}</span>
                  </div>
                </td>
                <td class="px-6 py-3.5">
                  <div class="flex items-center gap-2">
                    <span class={["w-1.5 h-1.5 rounded-full", activity.device_status_color]}></span>
                    <span class="text-sm text-slate-600 dark:text-slate-300 font-mono">{activity.device}</span>
                  </div>
                </td>
                <td class="px-6 py-3.5">
                  <span class={[
                    "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium",
                    activity.status_classes
                  ]}>
                    {activity.status}
                  </span>
                </td>
                <td class="px-6 py-3.5 text-sm text-slate-500 dark:text-slate-400">
                  {activity.time}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # -- Function components --

  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :change, :string, required: true
  attr :change_type, :atom, required: true
  attr :icon, :string, required: true
  attr :icon_bg, :string, required: true
  attr :icon_color, :string, required: true
  attr :delay, :string, default: ""

  defp stat_card(assigns) do
    ~H"""
    <div class={["bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5 animate-fade-in-up", @delay]}>
      <div class="flex items-center justify-between mb-3">
        <span class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">{@label}</span>
        <div class={["flex items-center justify-center w-9 h-9 rounded-lg", @icon_bg]}>
          <.icon name={@icon} class={["size-5", @icon_color]} />
        </div>
      </div>
      <div class="flex items-end justify-between">
        <div>
          <p class="text-2xl font-bold text-slate-900 dark:text-white animate-count-up">{@value}</p>
          <p class={[
            "text-xs mt-1",
            cond do
              @change_type == :positive -> "text-emerald-600 dark:text-emerald-400"
              @change_type == :warning -> "text-amber-600 dark:text-amber-400"
              true -> "text-slate-500 dark:text-slate-400"
            end
          ]}>
            {@change}
          </p>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :count, :integer, required: true
  attr :total, :integer, required: true
  attr :color, :string, required: true

  defp status_bar(assigns) do
    assigns = assign(assigns, :percent, round(assigns.count / assigns.total * 100))

    ~H"""
    <div>
      <div class="flex items-center justify-between mb-1.5">
        <div class="flex items-center gap-2">
          <span class={["w-2 h-2 rounded-full", @color]}></span>
          <span class="text-sm font-medium text-slate-700 dark:text-slate-300">{@label}</span>
        </div>
        <div class="flex items-center gap-2">
          <span class="text-sm font-semibold text-slate-900 dark:text-white">{@count}</span>
          <span class="text-xs text-slate-400">{@percent}%</span>
        </div>
      </div>
      <div class="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
        <div class={["h-full rounded-full transition-all duration-700 ease-out", @color]} style={"width: #{@percent}%"}></div>
      </div>
    </div>
    """
  end

  attr :name, :string, required: true
  attr :count, :integer, required: true
  attr :color, :string, required: true

  defp group_pill(assigns) do
    ~H"""
    <div class="flex items-center gap-2 px-3 py-2 bg-slate-50 dark:bg-slate-800 rounded-lg">
      <span class={["w-2 h-2 rounded-full", @color]}></span>
      <div class="flex-1 min-w-0">
        <p class="text-xs font-medium text-slate-700 dark:text-slate-300 truncate">{@name}</p>
        <p class="text-xs text-slate-500">{@count} devices</p>
      </div>
    </div>
    """
  end

  attr :version, :string, required: true
  attr :target, :string, required: true
  attr :devices, :integer, required: true
  attr :uploaded, :string, required: true

  defp firmware_item(assigns) do
    ~H"""
    <div class="flex items-center justify-between py-2">
      <div class="flex items-center gap-3">
        <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-slate-100 dark:bg-slate-800">
          <.icon name="hero-cube" class="size-4 text-slate-500" />
        </div>
        <div>
          <p class="text-sm font-medium text-slate-900 dark:text-white">{@version}</p>
          <p class="text-xs text-slate-500">{@target}</p>
        </div>
      </div>
      <div class="text-right">
        <p class="text-xs font-medium text-slate-600 dark:text-slate-300">{@devices} devices</p>
        <p class="text-xs text-slate-400">{@uploaded}</p>
      </div>
    </div>
    """
  end

  # -- Mock data --

  defp mock_stats do
    %{
      total_devices: 156,
      online_devices: 47,
      online_percent: 30,
      firmware_versions: 8,
      active_deployments: 3
    }
  end

  defp mock_recent_devices do
    [
      %{serial: "SHP-001-A7F3", nickname: "Gateway Alpha", status: :online, firmware: "2.4.1", group: "Production"},
      %{serial: "SHP-002-B8E4", nickname: "Sensor Hub 1", status: :online, firmware: "2.4.1", group: "Production"},
      %{serial: "SHP-003-C9D5", nickname: "Edge Node 3", status: :offline, firmware: "2.3.0", group: "Staging"},
      %{serial: "SHP-004-D0F6", nickname: nil, status: :online, firmware: "2.4.0", group: "Development"},
      %{serial: "SHP-005-E1A7", nickname: "Relay Beta", status: :offline, firmware: "2.2.1", group: nil}
    ]
  end

  defp mock_recent_activity do
    [
      %{
        event: "Firmware deployed",
        device: "SHP-001-A7F3",
        status: "Complete",
        status_classes: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
        time: "2 min ago",
        icon: "hero-rocket-launch",
        icon_bg: "bg-blue-500/10",
        icon_color: "text-blue-500",
        device_status_color: "bg-emerald-500"
      },
      %{
        event: "Device connected",
        device: "SHP-012-F2B8",
        status: "Online",
        status_classes: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
        time: "5 min ago",
        icon: "hero-signal",
        icon_bg: "bg-emerald-500/10",
        icon_color: "text-emerald-500",
        device_status_color: "bg-emerald-500"
      },
      %{
        event: "Update failed",
        device: "SHP-007-G3C9",
        status: "Failed",
        status_classes: "bg-rose-50 dark:bg-rose-500/10 text-rose-700 dark:text-rose-400",
        time: "12 min ago",
        icon: "hero-exclamation-triangle",
        icon_bg: "bg-rose-500/10",
        icon_color: "text-rose-500",
        device_status_color: "bg-rose-500"
      },
      %{
        event: "Device disconnected",
        device: "SHP-003-C9D5",
        status: "Offline",
        status_classes: "bg-slate-100 dark:bg-slate-500/10 text-slate-600 dark:text-slate-400",
        time: "18 min ago",
        icon: "hero-signal-slash",
        icon_bg: "bg-slate-200 dark:bg-slate-700",
        icon_color: "text-slate-500",
        device_status_color: "bg-slate-400"
      },
      %{
        event: "Firmware uploaded",
        device: "v2.4.1 (rpi4)",
        status: "Ready",
        status_classes: "bg-blue-50 dark:bg-blue-500/10 text-blue-700 dark:text-blue-400",
        time: "1 hr ago",
        icon: "hero-arrow-up-tray",
        icon_bg: "bg-violet-500/10",
        icon_color: "text-violet-500",
        device_status_color: "bg-blue-500"
      },
      %{
        event: "Group created",
        device: "Staging-West",
        status: "Active",
        status_classes: "bg-violet-50 dark:bg-violet-500/10 text-violet-700 dark:text-violet-400",
        time: "3 hr ago",
        icon: "hero-rectangle-group",
        icon_bg: "bg-violet-500/10",
        icon_color: "text-violet-500",
        device_status_color: "bg-violet-500"
      }
    ]
  end

  defp mock_firmware_status do
    [
      %{version: "v2.4.1", target: "rpi4", devices: 84, uploaded: "2 days ago"},
      %{version: "v2.4.0", target: "rpi4", devices: 42, uploaded: "2 weeks ago"},
      %{version: "v2.3.0", target: "rpi3", devices: 30, uploaded: "1 month ago"}
    ]
  end
end
