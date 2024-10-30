# Mirrored from https://gist.github.com/gboddin/d78823245b518edd54bfc2301c5f8882

# CyberPanel PSAUX attack/defense

This repo contains 2 things:

- A decryption script
- A list of files found on the threat-actor's server

## Ransomware status

We are currently aware of 3 separate groups encrypting CyberPanel instances. The extension they leave are:

- `.psaux`
- `.encryp`
- `.locked`

## Decryption

If your server was only targeted by PSAUX and files have the `.psaux` extension, due to a flaw in PSAUX's implementation, you should be able to use the decrypter.

