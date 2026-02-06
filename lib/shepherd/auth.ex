defmodule Shepherd.Auth do
  @moduledoc """
  Certificate-based device authentication.

  Devices sign `"serial:timestamp"` with their EC private key and present
  their certificate. The server verifies the cert chain back to the Fleet CA,
  then verifies the message signature using the device cert's public key.

  ## Timestamp Tolerance

  The default tolerance is 60 seconds to account for minor clock drift.
  This can be configured:

      config :shepherd, :timestamp_tolerance, 120
  """

  @default_timestamp_tolerance 60

  @doc """
  Verifies a device authentication attempt.

  Expects a map with string keys:
    - `"serial"` — claimed serial number
    - `"timestamp"` — unix timestamp (integer or string)
    - `"signature"` — base64-encoded ECDSA signature of `"serial:timestamp"`
    - `"cert"` — base64-encoded DER device certificate

  Returns `{:ok, %{serial, cert_fingerprint, cert_not_after}}` on success.
  """
  def verify_device_auth(params) do
    with {:ok, serial} <- fetch_string(params, "serial"),
         {:ok, timestamp} <- fetch_timestamp(params),
         {:ok, signature} <- fetch_base64(params, "signature"),
         {:ok, cert_der} <- fetch_base64(params, "cert"),
         {:ok, cert} <- parse_cert(cert_der),
         :ok <- verify_not_expired(cert),
         :ok <- verify_signed_by_ca(cert_der),
         {:ok, cert_serial} <- extract_serial(cert),
         :ok <- match_serial(cert_serial, serial),
         :ok <- verify_timestamp(timestamp),
         :ok <- verify_signature(cert, serial, timestamp, signature) do
      {:ok,
       %{
         serial: serial,
         cert_fingerprint: fingerprint(cert_der),
         cert_not_after: not_after(cert)
       }}
    end
  end

  @doc "Returns the parsed Fleet CA certificate from application config."
  def fleet_ca_cert do
    pem = Application.fetch_env!(:shepherd, :fleet_ca_pem)
    X509.Certificate.from_pem!(pem)
  end

  # --- Param extraction ---

  defp fetch_string(params, key) do
    case Map.fetch(params, key) do
      {:ok, value} when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, {:missing_param, key}}
    end
  end

  defp fetch_timestamp(params) do
    case Map.fetch(params, "timestamp") do
      {:ok, ts} when is_integer(ts) -> {:ok, ts}
      {:ok, ts} when is_binary(ts) ->
        case Integer.parse(ts) do
          {parsed, ""} -> {:ok, parsed}
          _ -> {:error, :invalid_timestamp}
        end
      _ -> {:error, :missing_timestamp}
    end
  end

  defp fetch_base64(params, key) do
    case Map.fetch(params, key) do
      {:ok, encoded} ->
        try do
          {:ok, Base.decode64!(encoded)}
        rescue
          _ -> {:error, {:invalid_base64, key}}
        end
      :error -> {:error, {:missing_param, key}}
    end
  end

  # --- Certificate verification ---

  defp parse_cert(der) do
    X509.Certificate.from_der(der)
  end

  defp verify_not_expired(cert) do
    if DateTime.compare(not_after(cert), DateTime.utc_now()) == :lt,
      do: {:error, :certificate_expired},
      else: :ok
  end

  defp verify_signed_by_ca(cert_der) do
    ca_public_key = X509.Certificate.public_key(fleet_ca_cert())

    # OTP decode gives us the signature as a plain binary
    {:"OTPCertificate", _tbs, _sig_algo, signature} =
      :public_key.pkix_decode_cert(cert_der, :otp)

    # TBS must come from the original DER — re-encoding would produce different
    # bytes and break the signature check.
    tbs_der = extract_tbs_der(cert_der)

    if :public_key.verify(tbs_der, :sha256, signature, ca_public_key),
      do: :ok,
      else: {:error, :not_signed_by_ca}
  end

  defp extract_serial(cert) do
    case X509.Certificate.subject(cert, "CN") do
      [serial] -> {:ok, serial}
      _ -> {:error, :missing_serial_in_cert}
    end
  end

  defp match_serial(serial, serial), do: :ok
  defp match_serial(_, _), do: {:error, :serial_mismatch}

  # --- Timestamp ---

  defp verify_timestamp(timestamp) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    tolerance = Application.get_env(:shepherd, :timestamp_tolerance, @default_timestamp_tolerance)
    diff = abs(now - timestamp)

    if diff <= tolerance do
      :ok
    else
      require Logger
      Logger.warning(
        "[Auth] Timestamp out of range: " <>
        "server=#{now} (#{DateTime.from_unix!(now)}), " <>
        "device=#{timestamp} (#{DateTime.from_unix!(timestamp)}), " <>
        "diff=#{diff}s (tolerance=#{tolerance}s)"
      )
      {:error, :timestamp_out_of_range}
    end
  end

  # --- Signature ---

  defp verify_signature(cert, serial, timestamp, signature) do
    message = "#{serial}:#{timestamp}"
    public_key = X509.Certificate.public_key(cert)

    if :public_key.verify(message, :sha256, signature, public_key),
      do: :ok,
      else: {:error, :invalid_signature}
  end

  # --- Helpers ---

  defp fingerprint(cert_der) do
    :crypto.hash(:sha256, cert_der) |> Base.encode16(case: :lower)
  end

  defp not_after(cert) do
    {:Validity, _not_before, not_after_time} = X509.Certificate.validity(cert)
    parse_asn1_time(not_after_time)
  end

  # UTCTime: "YYMMDDHHMMSSZ" — years 00-49 are 2000s, 50-99 are 1900s (RFC 5280)
  defp parse_asn1_time({:utcTime, time}) do
    time = to_string(time)
    yy = String.to_integer(String.slice(time, 0, 2))
    year = if yy >= 50, do: 1900 + yy, else: 2000 + yy

    utc_datetime(year, parse_int(time, 2, 2), parse_int(time, 4, 2),
      parse_int(time, 6, 2), parse_int(time, 8, 2), parse_int(time, 10, 2))
  end

  # GeneralizedTime: "YYYYMMDDHHMMSSZ" — used for years >= 2050
  defp parse_asn1_time({:generalTime, time}) do
    time = to_string(time)

    utc_datetime(parse_int(time, 0, 4), parse_int(time, 4, 2), parse_int(time, 6, 2),
      parse_int(time, 8, 2), parse_int(time, 10, 2), parse_int(time, 12, 2))
  end

  # Builds a UTC DateTime struct directly, avoiding Calendar.TimeZoneDatabase lookups.
  defp utc_datetime(year, month, day, hour, minute, second) do
    %DateTime{
      year: year, month: month, day: day,
      hour: hour, minute: minute, second: second,
      microsecond: {0, 0}, calendar: Calendar.ISO,
      time_zone: "UTC", utc_offset: 0, std_offset: 0, zone_abbr: "UTC"
    }
  end

  defp parse_int(string, offset, length) do
    String.to_integer(String.slice(string, offset, length))
  end

  # --- DER helpers (for extracting raw TBS bytes without re-encoding) ---------

  # Certificate ::= SEQUENCE { TBSCertificate, SignatureAlgorithm, SignatureValue }
  # Returns the raw DER of the TBSCertificate (first element of the outer SEQUENCE).
  defp extract_tbs_der(cert_der) do
    <<0x30, after_tag::binary>> = cert_der
    {_outer_len, contents} = parse_der_length(after_tag)
    take_tlv(contents)
  end

  # Returns the raw bytes of the first TLV (tag + length + value) in *bin*.
  defp take_tlv(<<_tag, after_tag::binary>> = bin) do
    {content_len, after_len} = parse_der_length(after_tag)
    len_field_size = byte_size(after_tag) - byte_size(after_len)
    binary_part(bin, 0, 1 + len_field_size + content_len)
  end

  defp parse_der_length(<<len, rest::binary>>) when len < 0x80 do
    {len, rest}
  end

  defp parse_der_length(<<0x81, len, rest::binary>>) do
    {len, rest}
  end

  defp parse_der_length(<<0x82, hi, lo, rest::binary>>) do
    {hi * 256 + lo, rest}
  end
end
