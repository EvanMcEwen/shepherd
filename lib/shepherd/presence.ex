defmodule Shepherd.Presence do
  @moduledoc """
  Tracks online devices using Phoenix Presence.

  Devices are tracked in the "devices:lobby" topic when they connect.
  Use `list/0` to get all online devices with their metadata.
  """

  use Phoenix.Presence,
    otp_app: :shepherd,
    pubsub_server: Shepherd.PubSub

  @topic "devices:lobby"

  @doc """
  Returns the topic used for device presence tracking.
  """
  def topic, do: @topic

  @doc """
  Lists all online devices with their presence metadata.

  Returns a map of serial => presence_info.
  """
  def list_online do
    list(@topic)
  end

  @doc """
  Returns the count of currently online devices.
  """
  def online_count do
    @topic
    |> list()
    |> map_size()
  end

  @doc """
  Checks if a device with the given serial is currently online.
  """
  def online?(serial) do
    @topic
    |> list()
    |> Map.has_key?(serial)
  end
end
