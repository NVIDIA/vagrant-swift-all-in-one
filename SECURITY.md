# Security Policy: vagrant-swift-all-in-one

## Reporting a Vulnerability

If you discover a potential security vulnerability, please **do not open a
public issue or pull request.**

- Report it through the [NVIDIA Vulnerability Disclosure Program](https://www.nvidia.com/en-us/security/) (preferred).
- Email [psirt@nvidia.com](mailto:psirt@nvidia.com). The [NVIDIA public PGP key](https://www.nvidia.com/en-us/security/pgp-key) is available for encrypted email.
- Use this repository's **Security** tab and **Report a vulnerability** when private vulnerability reporting is available.

Please include the affected project version or commit, the vulnerability type,
reproduction steps, proof-of-concept code if available, and an impact
assessment. NVIDIA PSIRT will acknowledge the report, validate it, coordinate a
fix, and publish security information as appropriate.

## Security Architecture & Context

vagrant-swift-all-in-one is a Vagrant and Chef-based development toolchain that
provisions an OpenStack Swift all-in-one environment for local testing. It is
not intended to provide a production-ready Swift deployment or a secure
multi-tenant service.

The repository contains Vagrant provider configuration, Chef recipes, test
helpers, and generated configuration for Swift, optional encryption/KMIP
testing, and optional metrics collection. Provisioning obtains operating-system
packages, Python tooling, and Swift-related source dependencies, then exposes
the test environment through its configured private Vagrant network. An optional
cloud provider path consumes credentials supplied by the operator.

**Repository Exposure Classification:** Public.
Basis: the source is a publicly readable open-source GitHub repository; this document is written for public consumption.

**Service Exposure Classification:** External / Regulated (high confidence).
Basis: this is externally distributed developer tooling that provisions network services and can consume operator cloud credentials; repository evidence identifies development and test use rather than a production deployment.

The host checkout, its environment variables, the selected Vagrant provider,
and the guest operating system are trust boundaries. The VM receives the
checkout through a synced folder and, by default, has access to a forwarded SSH
agent. The generated Swift proxy accepts requests within the configured Vagrant
network; its test authentication and optional no-auth endpoint are deliberately
suited only to an isolated development environment.

### Threat Model

1. **Exposure of development Swift endpoints:** The generated proxy includes test credentials and an optional no-auth listener. If a Vagrant network or cloud security group is made reachable by untrusted users, an attacker could access test objects or administrative test capabilities.
2. **Compromise of forwarded SSH credentials:** `Vagrantfile` enables SSH agent forwarding. A compromise of a guest VM can allow use of keys loaded in the host's forwarded agent while that guest is running.
3. **Untrusted provisioning inputs:** Chef recipes build shell commands from configurable repository URLs, branch names, and `EXTRA_KEY`. Malicious or incorrectly sourced local configuration can alter guest provisioning or authorized keys.
4. **Dependency and bootstrap supply-chain compromise:** Provisioning downloads a Python bootstrap script, packages, Git repositories, and optional release archives. Mutable branches and artifacts that are not integrity-verified can introduce compromised code into the guest.
5. **Cloud credential or network misconfiguration:** The optional cloud provider configuration reads credentials and security-group settings from the operator environment. Overly broad permissions or network rules can expose the development VM or associated cloud resources.
6. **Metrics and diagnostic data exposure:** Optional Prometheus and StatsD exporter services expose operational data for the test stack. Those endpoints must remain limited to the intended development network.

### Critical Security Assumptions

- The project is used only for development, testing, or isolated experimentation; it is not deployed as a production Swift service.
- The Vagrant private network, any provider-specific network configuration, and optional cloud security groups restrict access to trusted operators.
- Test accounts, fixture credentials, and example encryption material in this repository are non-production values and are never reused for real services or accounts.
- Operators provide only trusted values for Vagrant and Chef environment variables, including repository locations, branches, SSH keys, package choices, and cloud credentials.
- The host is trusted to protect its checkout, SSH agent, cloud credentials, and virtualization provider; the guest is not a security boundary for host credentials while agent forwarding is enabled.
- Operators independently verify the provenance and suitability of downloaded packages, source repositories, Vagrant boxes, and optional tooling for their environment.
