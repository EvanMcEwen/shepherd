defmodule ShepherdWeb.DeploymentsLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Deployments")
     |> assign(:deployments, mock_deployments())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:deployments} page_title="Deployments">
      <div class="flex items-center justify-between mb-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-bold text-slate-900 dark:text-white">Deployments</h2>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Track firmware rollouts across your fleet</p>
        </div>
        <button class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg shadow-sm transition-colors">
          <.icon name="hero-rocket-launch" class="size-4" />
          New Deployment
        </button>
      </div>

      <div class="space-y-4 animate-fade-in-up delay-150">
        <div
          :for={deploy <- @deployments}
          class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6"
        >
          <div class="flex items-start justify-between mb-4">
            <div class="flex items-center gap-3">
              <div class={["flex items-center justify-center w-10 h-10 rounded-lg", deploy.icon_bg]}>
                <.icon name={deploy.icon} class={["size-5", deploy.icon_color]} />
              </div>
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="text-sm font-semibold text-slate-900 dark:text-white">{deploy.name}</h3>
                  <span class={["inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium", deploy.status_classes]}>
                    {deploy.status}
                  </span>
                </div>
                <p class="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                  {deploy.firmware} &rarr; {deploy.group} &middot; Started {deploy.started}
                </p>
              </div>
            </div>
            <button class="p-1.5 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
              <.icon name="hero-ellipsis-vertical" class="size-4" />
            </button>
          </div>

          <%!-- Progress --%>
          <div class="mb-3">
            <div class="flex items-center justify-between mb-1.5">
              <span class="text-xs text-slate-500 dark:text-slate-400">{deploy.completed}/{deploy.total} devices</span>
              <span class="text-xs font-medium text-slate-700 dark:text-slate-300">{deploy.percent}%</span>
            </div>
            <div class="w-full h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div class={["h-full rounded-full transition-all duration-500", deploy.bar_color]} style={"width: #{deploy.percent}%"}></div>
            </div>
          </div>

          <div class="flex items-center gap-4 text-xs text-slate-500 dark:text-slate-400">
            <span class="flex items-center gap-1">
              <span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
              {deploy.success} succeeded
            </span>
            <span class="flex items-center gap-1">
              <span class="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
              {deploy.in_progress} in progress
            </span>
            <span class="flex items-center gap-1">
              <span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span>
              {deploy.failed} failed
            </span>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp mock_deployments do
    [
      %{
        name: "Production Rollout",
        firmware: "v2.4.1",
        group: "Production",
        status: "In Progress",
        status_classes: "bg-blue-50 dark:bg-blue-500/10 text-blue-700 dark:text-blue-400",
        started: "2 hours ago",
        total: 84,
        completed: 62,
        percent: 74,
        success: 58,
        in_progress: 4,
        failed: 0,
        bar_color: "bg-blue-500",
        icon: "hero-rocket-launch",
        icon_bg: "bg-blue-500/10",
        icon_color: "text-blue-500"
      },
      %{
        name: "Staging Canary",
        firmware: "v2.5.0-rc2",
        group: "Canary",
        status: "In Progress",
        status_classes: "bg-blue-50 dark:bg-blue-500/10 text-blue-700 dark:text-blue-400",
        started: "45 min ago",
        total: 8,
        completed: 3,
        percent: 38,
        success: 3,
        in_progress: 2,
        failed: 0,
        bar_color: "bg-blue-500",
        icon: "hero-beaker",
        icon_bg: "bg-amber-500/10",
        icon_color: "text-amber-500"
      },
      %{
        name: "Staging Update",
        firmware: "v2.4.1",
        group: "Staging",
        status: "Complete",
        status_classes: "bg-emerald-50 dark:bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
        started: "Yesterday",
        total: 32,
        completed: 32,
        percent: 100,
        success: 31,
        in_progress: 0,
        failed: 1,
        bar_color: "bg-emerald-500",
        icon: "hero-check-circle",
        icon_bg: "bg-emerald-500/10",
        icon_color: "text-emerald-500"
      },
      %{
        name: "Dev RC Deploy",
        firmware: "v2.5.0-rc1",
        group: "Development",
        status: "Failed",
        status_classes: "bg-rose-50 dark:bg-rose-500/10 text-rose-700 dark:text-rose-400",
        started: "3 days ago",
        total: 24,
        completed: 18,
        percent: 75,
        success: 15,
        in_progress: 0,
        failed: 3,
        bar_color: "bg-rose-500",
        icon: "hero-exclamation-triangle",
        icon_bg: "bg-rose-500/10",
        icon_color: "text-rose-500"
      }
    ]
  end
end
