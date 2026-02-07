defmodule Shepherd.Firmware.S3 do
  @moduledoc """
  S3 operations for firmware storage using pre-signed URLs.
  All firmware files are stored in a private S3 bucket.
  """

  @doc """
  Upload a file to S3.
  Returns {:ok, s3_key} on success, {:error, reason} on failure.
  """
  def upload(s3_key, local_path, opts \\ []) do
    bucket = get_bucket()
    binary = File.read!(local_path)
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    bucket
    |> ExAws.S3.put_object(s3_key, binary, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, s3_key}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate a pre-signed download URL for an S3 object.
  Returns {:ok, url} on success.

  Options:
    * :expires_in - URL expiration time in seconds (default: 3600, 1 hour)
  """
  def generate_presigned_download_url(s3_key, opts \\ []) do
    bucket = get_bucket()
    expires_in = Keyword.get(opts, :expires_in, 3600)

    config = ExAws.Config.new(:s3)
    {:ok, url} = ExAws.S3.presigned_url(config, :get, bucket, s3_key, expires_in: expires_in)
    {:ok, url}
  end

  @doc """
  Delete a firmware file from S3.
  Returns {:ok, _} on success, {:error, reason} on failure.
  """
  def delete(s3_key) do
    bucket = get_bucket()

    bucket
    |> ExAws.S3.delete_object(s3_key)
    |> ExAws.request()
  end

  defp get_bucket do
    Application.get_env(:shepherd, :firmware_s3_bucket) ||
      raise "firmware_s3_bucket not configured"
  end
end
