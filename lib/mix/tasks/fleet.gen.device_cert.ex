defmodule Mix.Tasks.Fleet.Gen.DeviceCert do
  use Mix.Task

  @shortdoc "Generates a device key and certificate signed by the Fleet CA"

  @moduledoc """
  Generates an EC key pair and a certificate for a device, signed by the
  Fleet CA. The certificate CN is set to the device serial number.

      $ mix fleet.gen.device_cert --serial MY_DEVICE_001

  Outputs to `priv/devices/<serial>/`:
    - `device_key.pem`
    - `device_cert.pem`
    - `device_cert.der`

  Requires that the Fleet CA has been generated first via `mix fleet.gen.ca`.
  """

  @switches [serial: :string]

  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)

    unless opts[:serial] do
      Mix.raise("Usage: mix fleet.gen.device_cert --serial SERIAL")
    end

    serial = opts[:serial]
    ca_key_path = "priv/ca/fleet_ca_key.pem"
    ca_cert_path = "priv/ca/fleet_ca.pem"

    unless File.exists?(ca_key_path) && File.exists?(ca_cert_path) do
      Mix.raise("Fleet CA not found. Run `mix fleet.gen.ca` first.")
    end

    ca_key = X509.PrivateKey.from_pem!(File.read!(ca_key_path))
    ca_cert = X509.Certificate.from_pem!(File.read!(ca_cert_path))

    device_key = X509.PrivateKey.new_ec(:secp256r1)

    device_cert =
      device_key
      |> X509.PublicKey.derive()
      |> X509.Certificate.new(
        "/CN=#{serial}",
        ca_cert,
        ca_key,
        validity: 1825
      )

    dir = Path.join("priv/devices", serial)
    File.mkdir_p!(dir)

    File.write!(Path.join(dir, "device_key.pem"), X509.PrivateKey.to_pem(device_key))
    File.write!(Path.join(dir, "device_cert.pem"), X509.Certificate.to_pem(device_cert))
    File.write!(Path.join(dir, "device_cert.der"), X509.Certificate.to_der(device_cert))

    Mix.shell().info("Generated device credentials in #{dir}/")
  end
end
