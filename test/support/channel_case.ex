defmodule ShepherdWeb.ChannelCase do
  @moduledoc """
  This module defines the setup for tests requiring
  testing of Phoenix channels.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest

      @endpoint ShepherdWeb.Endpoint
    end
  end

  setup tags do
    Shepherd.DataCase.setup_sandbox(tags)
    :ok
  end
end
