defmodule ShepherdWeb.FirmwareLive do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Firmware")
     |> assign(:firmwares, mock_firmwares())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_page={:firmware} page_title="Firmware">
      <div class="flex items-center justify-between mb-6 animate-fade-in">
        <div>
          <h2 class="text-2xl font-bold text-slate-900 dark:text-white">Firmware</h2>
          <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">Manage firmware versions and uploads</p>
        </div>
        <button class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg shadow-sm transition-colors">
          <.icon name="hero-arrow-up-tray" class="size-4" />
          Upload Firmware
        </button>
      </div>

      <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden animate-fade-in-up delay-150">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead>
              <tr class="border-b border-slate-100 dark:border-slate-800">
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Version</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Target</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Application</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Size</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Devices</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Uploaded</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
              <tr :for={fw <- @firmwares} class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                <td class="px-6 py-4">
                  <span class="text-sm font-semibold font-mono text-slate-900 dark:text-white">{fw.version}</span>
                </td>
                <td class="px-6 py-4">
                  <span class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                    {fw.target}
                  </span>
                </td>
                <td class="px-6 py-4 text-sm text-slate-600 dark:text-slate-300">{fw.application}</td>
                <td class="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">{fw.size}</td>
                <td class="px-6 py-4 text-sm font-medium text-slate-900 dark:text-white">{fw.devices}</td>
                <td class="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">{fw.uploaded}</td>
                <td class="px-6 py-4 text-right">
                  <button class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-emerald-600 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-500/10 rounded-lg transition-colors">
                    <.icon name="hero-rocket-launch-micro" class="size-3.5" />
                    Deploy
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp mock_firmwares do
    [
      %{version: "v2.4.1", target: "rpi4", application: "shepherd", size: "14.2 MB", devices: 84, uploaded: "Feb 7, 2026"},
      %{version: "v2.4.0", target: "rpi4", application: "shepherd", size: "14.1 MB", devices: 42, uploaded: "Jan 23, 2026"},
      %{version: "v2.5.0-rc2", target: "rpi4", application: "shepherd", size: "14.3 MB", devices: 8, uploaded: "Feb 8, 2026"},
      %{version: "v2.5.0-rc1", target: "rpi4", application: "shepherd", size: "14.3 MB", devices: 24, uploaded: "Feb 1, 2026"},
      %{version: "v2.3.0", target: "rpi3", application: "shepherd", size: "12.8 MB", devices: 30, uploaded: "Dec 12, 2025"},
      %{version: "v2.2.1", target: "rpi3", application: "shepherd", size: "12.5 MB", devices: 8, uploaded: "Nov 5, 2025"}
    ]
  end
end
