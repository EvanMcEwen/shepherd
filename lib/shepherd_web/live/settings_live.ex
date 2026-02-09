defmodule ShepherdWeb.SettingsLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Settings")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:settings} page_title="Settings">
      <div class="mb-6 animate-fade-in">
        <h2 class="text-2xl font-bold text-slate-900 dark:text-white">Settings</h2>
        <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Configure your Shepherd instance</p>
      </div>

      <div class="space-y-6 animate-fade-in-up delay-150">
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white mb-1">General</h3>
          <p class="text-xs text-slate-500 dark:text-slate-400 mb-4">Basic instance configuration</p>
          <div class="space-y-4">
            <div>
              <label class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1.5">Instance Name</label>
              <input
                type="text"
                value="Shepherd Production"
                class="w-full max-w-md px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-colors"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1.5">Fleet CA Certificate</label>
              <div class="flex items-center gap-3 max-w-md px-4 py-3 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg">
                <.icon name="hero-shield-check" class="size-5 text-emerald-500" />
                <div class="flex-1">
                  <p class="text-sm font-medium text-slate-900 dark:text-white">fleet-ca.pem</p>
                  <p class="text-xs text-slate-500">Expires Mar 2030</p>
                </div>
                <button class="text-xs font-medium text-emerald-600 dark:text-emerald-400 hover:text-emerald-700 transition-colors">Replace</button>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6">
          <h3 class="text-sm font-semibold text-slate-900 dark:text-white mb-1">S3 Storage</h3>
          <p class="text-xs text-slate-500 dark:text-slate-400 mb-4">Firmware storage configuration</p>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 max-w-2xl">
            <div>
              <label class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1.5">Bucket</label>
              <input
                type="text"
                value="shepherd-firmware-prod"
                class="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-colors"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-slate-700 dark:text-slate-300 mb-1.5">Region</label>
              <input
                type="text"
                value="us-east-1"
                class="w-full px-3 py-2 text-sm bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 transition-colors"
              />
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
