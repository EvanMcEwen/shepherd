defmodule Mix.Tasks.Fleet.Gen.Ca do
  use Mix.Task

  @shortdoc "Generates the Fleet CA key and certificate"

  @moduledoc """
  Generates an EC (secp256r1) key pair for the Fleet CA and a self-signed
  CA certificate with 10-year validity.

      $ mix fleet.gen.ca

  Outputs:
    - `priv/ca/fleet_ca_key.pem` (permissions 0o600)
    - `priv/ca/fleet_ca.pem`

  The CA private key is restricted to 0o600. It should never leave the
  build machine.
  """

  def run(_args) do
    ca_key = X509.PrivateKey.new_ec(:secp256r1)

    ca_cert =
      X509.Certificate.self_signed(
        ca_key,
        "/CN=Fleet CA",
        template: :root_ca,
        validity: 3650
      )

    dir = "priv/ca"
    File.mkdir_p!(dir)

    key_path = Path.join(dir, "fleet_ca_key.pem")
    cert_path = Path.join(dir, "fleet_ca.pem")

    File.write!(key_path, X509.PrivateKey.to_pem(ca_key))
    File.chmod!(key_path, 0o600)
    File.write!(cert_path, X509.Certificate.to_pem(ca_cert))

    Mix.shell().info("Generated Fleet CA:")
    Mix.shell().info("  key:  #{key_path}")
    Mix.shell().info("  cert: #{cert_path}")
  end
end
