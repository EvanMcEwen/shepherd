defmodule ShepherdWeb.GroupsLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Groups")
     |> assign(:groups, mock_groups())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:groups} page_title="Groups">
      <div class="flex items-center justify-between mb-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-bold text-slate-900 dark:text-white">Groups</h2>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Organize devices into logical groups for batch management</p>
        </div>
        <button class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg shadow-sm transition-colors">
          <.icon name="hero-plus" class="size-4" />
          Create Group
        </button>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 animate-fade-in-up delay-150">
        <div
          :for={group <- @groups}
          class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 hover:border-slate-300 dark:hover:border-slate-700 transition-colors group/card cursor-pointer"
        >
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-3">
              <div class={["flex items-center justify-center w-10 h-10 rounded-lg", group.color_bg]}>
                <.icon name="hero-rectangle-group" class={["size-5", group.color_text]} />
              </div>
              <div>
                <h3 class="text-sm font-semibold text-slate-900 dark:text-white">{group.name}</h3>
                <p class="text-xs text-slate-500 dark:text-slate-400">{group.description}</p>
              </div>
            </div>
            <button class="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 opacity-0 group-hover/card:opacity-100 transition-all">
              <.icon name="hero-ellipsis-vertical" class="size-4" />
            </button>
          </div>

          <div class="flex items-center justify-between pt-4 border-t border-slate-100 dark:border-slate-800">
            <div class="flex items-center gap-4">
              <div class="text-center">
                <p class="text-lg font-bold text-slate-900 dark:text-white">{group.device_count}</p>
                <p class="text-xs text-slate-500">Devices</p>
              </div>
              <div class="text-center">
                <p class="text-lg font-bold text-emerald-600 dark:text-emerald-400">{group.online_count}</p>
                <p class="text-xs text-slate-500">Online</p>
              </div>
            </div>
            <div class="text-right">
              <p class="text-xs font-medium text-slate-600 dark:text-slate-300 font-mono">{group.firmware || "No firmware"}</p>
              <p class="text-xs text-slate-400">Target firmware</p>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp mock_groups do
    [
      %{name: "Production", description: "Live production devices", device_count: 84, online_count: 38, firmware: "v2.4.1", color_bg: "bg-emerald-500/10", color_text: "text-emerald-500"},
      %{name: "Staging", description: "Pre-production testing", device_count: 32, online_count: 5, firmware: "v2.4.1", color_bg: "bg-blue-500/10", color_text: "text-blue-500"},
      %{name: "Development", description: "Developer test devices", device_count: 24, online_count: 4, firmware: "v2.5.0-rc1", color_bg: "bg-violet-500/10", color_text: "text-violet-500"},
      %{name: "Canary", description: "Early release channel", device_count: 8, online_count: 3, firmware: "v2.5.0-rc2", color_bg: "bg-amber-500/10", color_text: "text-amber-500"},
      %{name: "Legacy", description: "Older hardware, limited updates", device_count: 8, online_count: 0, firmware: "v2.2.1", color_bg: "bg-slate-500/10", color_text: "text-slate-500"}
    ]
  end
end
