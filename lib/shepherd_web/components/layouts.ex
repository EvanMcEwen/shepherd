defmodule ShepherdWeb.Layouts do
  @moduledoc """
  Layout components for the Shepherd admin interface.
  """
  use ShepherdWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders the main admin application layout with sidebar navigation and top bar.

  ## Examples

      <Layouts.app flash={@flash} current_page={:dashboard}>
        <h1>Dashboard content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current scope"

  attr :current_page, :atom,
    default: :dashboard,
    doc: "the current active page for nav highlighting"

  attr :page_title, :string,
    default: nil,
    doc: "optional page title shown in the top bar"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="flex h-screen bg-slate-50 dark:bg-slate-950 overflow-hidden">
      <%!-- Sidebar --%>
      <div class="flex flex-col w-64 shrink-0 bg-slate-900 dark:bg-slate-950 border-r border-slate-800">
        <%!-- Logo --%>
        <div class="flex items-center gap-3 px-6 h-16 border-b border-slate-800">
          <div class="flex items-center justify-center w-8 h-8 rounded-lg bg-emerald-500/10">
            <.icon name="hero-shield-check-solid" class="size-5 text-emerald-400" />
          </div>
          <span class="text-lg font-semibold text-white tracking-tight">Shepherd</span>
        </div>

        <%!-- Navigation --%>
        <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          <.nav_item
            icon="hero-squares-2x2"
            label="Dashboard"
            href={~p"/"}
            active={@current_page == :dashboard}
          />
          <.nav_item
            icon="hero-cpu-chip"
            label="Devices"
            href={~p"/devices"}
            active={@current_page == :devices}
          />
          <.nav_item
            icon="hero-rectangle-group"
            label="Groups"
            href={~p"/groups"}
            active={@current_page == :groups}
          />
          <.nav_item
            icon="hero-arrow-up-tray"
            label="Firmware"
            href={~p"/firmware"}
            active={@current_page == :firmware}
          />
          <.nav_item
            icon="hero-rocket-launch"
            label="Deployments"
            href={~p"/deployments"}
            active={@current_page == :deployments}
          />

          <div class="pt-4 mt-4 border-t border-slate-800">
            <.nav_item
              icon="hero-cog-6-tooth"
              label="Settings"
              href={~p"/settings"}
              active={@current_page == :settings}
            />
          </div>
        </nav>

        <%!-- Sidebar footer --%>
        <div class="px-4 py-4 border-t border-slate-800">
          <div class="flex items-center gap-3">
            <div class="flex items-center justify-center w-8 h-8 rounded-full bg-slate-700 text-slate-300 text-xs font-medium">
              EA
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-slate-200 truncate">Admin</p>
              <p class="text-xs text-slate-500 truncate">admin@shepherd.io</p>
            </div>
          </div>
        </div>
      </div>

      <%!-- Main content --%>
      <div class="flex-1 flex flex-col min-w-0">
        <%!-- Top bar --%>
        <header class="sticky top-0 z-10 flex items-center justify-between h-16 px-6 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800">
          <div class="flex items-center gap-4">
            <%= if @page_title do %>
              <h1 class="text-lg font-semibold text-slate-900 dark:text-slate-100">{@page_title}</h1>
            <% end %>
          </div>

          <div class="flex items-center gap-3">
            <%!-- Search --%>
            <div class="hidden md:flex items-center gap-2 px-3 py-1.5 text-sm text-slate-400 bg-slate-100 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 hover:border-slate-300 dark:hover:border-slate-600 transition-colors cursor-pointer">
              <.icon name="hero-magnifying-glass-micro" class="size-4" />
              <span>Search...</span>
              <kbd class="hidden sm:inline-flex items-center px-1.5 py-0.5 text-xs font-mono text-slate-400 bg-white dark:bg-slate-700 rounded border border-slate-200 dark:border-slate-600">/</kbd>
            </div>

            <.theme_toggle />

            <%!-- Notifications --%>
            <button class="relative p-2 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors">
              <.icon name="hero-bell" class="size-5" />
              <span class="absolute top-1.5 right-1.5 w-2 h-2 bg-rose-500 rounded-full"></span>
            </button>
          </div>
        </header>

        <%!-- Page content --%>
        <main class="flex-1 overflow-y-auto">
          <div class="px-6 py-6 max-w-7xl mx-auto">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, default: false

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class={[
        "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-all duration-150",
        if(@active,
          do: "bg-emerald-500/10 text-emerald-400",
          else: "text-slate-400 hover:text-slate-200 hover:bg-slate-800"
        )
      ]}
    >
      <.icon name={@icon} class={[
        "size-5",
        if(@active, do: "text-emerald-400", else: "text-slate-500")
      ]} />
      {@label}
      <%= if @active do %>
        <span class="ml-auto w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
      <% end %>
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="flex items-center gap-0.5 p-1 bg-slate-100 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700">
      <button
        class="p-1.5 rounded-md text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors [[data-theme=light]_&]:bg-white [[data-theme=light]_&]:text-slate-700 [[data-theme=light]_&]:shadow-sm"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>
      <button
        class={[
          "p-1.5 rounded-md text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors",
          "[:not([data-theme])_&]:bg-white [:not([data-theme])_&]:text-slate-700 [:not([data-theme])_&]:shadow-sm"
        ]}
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>
      <button
        class="p-1.5 rounded-md text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors [[data-theme=dark]_&]:bg-slate-700 [[data-theme=dark]_&]:text-slate-200 [[data-theme=dark]_&]:shadow-sm"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end
end
