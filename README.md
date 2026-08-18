# Wazuh + Suricata SOC Detection Lab

A self-built, cloud-hosted SIEM/IDS detection lab used to simulate real attack
techniques and validate end-to-end detection, triage, and response, from
infrastructure provisioning through alert generation and incident
documentation.

---

## Objective

Build a functioning Security Operations Center (SOC) detection pipeline from
the ground up: not just deploy a tool, but prove the ability to provision
infrastructure, configure a SIEM and network IDS, generate realistic attack
traffic, triage the resulting alerts, and document findings the way an
analyst would in a real SOC. The goal was to demonstrate the full lifecycle:
**infrastructure, detection, investigation, response, and lessons learned.**

---

## Architecture

- **Cloud Provider:** AWS (EC2, provisioned via Terraform)
- **SIEM:** Wazuh 4.8.2 (Docker Compose, single-node deployment)
- **Network IDS:** Suricata (monitoring live traffic, feeding `eve.json` into Wazuh)
- **Host OS:** Ubuntu 22.04
- **IaC:** Terraform (`main.tf`, `variables.tf`, `outputs.tf`, `user_data.sh`)

![Wazuh Dashboard Overview](screenshots/01-dashboard-overview/Wazuh%20Dashboard.png)

---

## Repository Structure

```
├── main.tf / variables.tf / outputs.tf   # Terraform IaC for the EC2 host
├── attack-simulations/                   # Repeatable bash scripts per incident
├── incident-reports/                     # Filled-in SOC-style incident reports (PDF)
├── screenshots/                          # Dashboard and alert evidence, organized per incident
└── README.md
```

---

## Steps

### 1. Infrastructure Provisioning
Provisioned the lab host on AWS EC2 using Terraform: instance sizing,
security group rules (restricted SSH ingress), and a `user_data.sh` bootstrap
script to install Docker and pull the Wazuh single-node Docker stack on
first boot.

### 2. SIEM & IDS Deployment
Deployed Wazuh manager, indexer, and dashboard via Docker Compose. Installed
and configured Suricata as a network IDS on the host, feeding parsed alerts
(`eve.json`) into Wazuh as a monitored log source alongside standard system
logs (`auth.log`, `syslog`).

### 3. Agent Configuration & Tuning
Enrolled the host as a Wazuh agent and iteratively corrected the agent
configuration: fixing malformed XML, restoring a missing `<syscheck>`
block, enabling real-time File Integrity Monitoring on user-facing
directories, and tuning the local event buffer (`client_buffer`) to prevent
event loss during high-volume bursts.

### 4. Attack Simulation
Executed four distinct, reproducible attack simulations against the lab
environment, each scripted in `/attack-simulations` and mapped to a specific
MITRE ATT&CK technique.

### 5. Detection, Triage & Documentation
For each simulated attack, verified the alert in the Wazuh dashboard and raw
alert log, investigated the supporting evidence, rendered a verdict
(True Positive / False Positive), and documented the full incident using a
consistent SOC-style report template (see `/incident-reports`).

---

## Simulated Attacks & Detections

| # | Attack | MITRE ATT&CK | Tactic | Detection Layer | Report |
|---|--------|--------------|--------|------------------|--------|
| 1 | SSH Brute Force (Hydra) | T1110 | Credential Access | Wazuh, SSH auth-failure rules | [SIM-001](incident-reports/SIM-001-brute-force.pdf) |
| 2 | Unauthorized Sudo Attempt | T1548.003 | Privilege Escalation | Wazuh, sudo rule group | [SIM-002](incident-reports/SIM-002-unauthorized-sudo.pdf) |
| 3 | Malicious File (EICAR) via FIM | T1204.002 | Execution | Wazuh, real-time FIM | [SIM-003](incident-reports/SIM-003-malicious-file-fim.pdf) |
| 4 | Unauthorized Account + Group Creation | T1136.001 | Persistence | Wazuh, account/group creation rules | [SIM-004](incident-reports/SIM-004-persistence-account-creation.pdf) |

### Incident 1: SSH Brute Force
![Brute Force Alert](screenshots/02-brute-force-alert/Wazuh%20Dashboard%20-%20Brute%20Force%20Alert%282%29.png)

### Incident 2: Unauthorized Sudo Attempt
![Sudo Alert](screenshots/03-sudo-alert/First%20Time%20Sudo%20User.png)

### Incident 3: Malicious File / FIM Detection
![FIM Alert](screenshots/04-fim-alert/Wazuh%20Dashoard%20-%20FIM%20Alert.png)

### Incident 4: Persistence via Account Creation
![Persistence Alert](screenshots/05-persistence-alert/Wazuh%20Dashboard%20-%20Backdoor%20Creation%20Alert.png)

---

## Alert Tuning

Beyond detection, this lab also involved hands-on rule tuning to manage
noise and validate custom detection logic, including suppressing a
high-frequency, low-value external scan rule and building a custom
critical-severity test rule to validate the alerting pipeline end-to-end.

![Alert Tuning](screenshots/Alert%20Tuning/Wazuh%20Alert%20Tuning%20%28Clear%20Queue%29.png)

---

## Lessons Learned

Several real, non-trivial troubleshooting findings came out of this build,
documented here because working through them was as valuable as the
detections themselves:

- **Default FIM paths don't cover common attack landing zones.** Wazuh's
  default `syscheck` configuration does not monitor `/tmp` or user download
  directories. Real-world payloads often land exactly there. Closing this
  gap required explicitly adding monitored paths with real-time monitoring
  enabled, rather than relying on the default 12-hour scheduled scan.

- **TLS-encrypted traffic is a blind spot for network IDS without
  interception.** Suricata could not inspect the contents of an HTTPS
  download, since payload bytes are encrypted on the wire. This confirmed
  that file-based detection (FIM), not network detection, was the correct
  and necessary layer for catching a malicious file delivered over HTTPS.

- **A single malformed XML element can silently break the entire agent.**
  An invalid `<client_buffer>` placement, and later a duplicated root
  `<ossec_config>` element from a config rewrite, both caused the agent to
  fail outright with minimal warning. Validating configuration with
  `xmllint` before every restart became a standard part of the workflow.

- **Wazuh does not alert on routine, authorized sudo usage by default,**
  only failed/unauthorized attempts trigger a rule. This is sensible default
  behavior (avoids alert fatigue on normal admin activity) but is worth
  understanding explicitly rather than assuming all privileged actions are
  logged as alerts.

- **Self-initiated scans against your own host don't always trigger
  network IDS signatures** the way external attacker traffic does. Many
  Suricata scan signatures are threshold- or pattern-based and tuned for
  real-world attacker behavior, not a handful of manually-run test
  connections. Real, unsolicited scanning traffic from the public internet
  was ultimately what confirmed the network-detection layer was working.

---

## Tech Stack

`Terraform` `AWS EC2` `Docker / Docker Compose` `Wazuh 4.8.2` `Suricata` `Ubuntu 22.04` `Bash` `MITRE ATT&CK`

---

## About This Project

Built as a hands-on portfolio project to demonstrate practical SOC analyst
and detection engineering skills: infrastructure-as-code, SIEM
configuration, log source integration, attack simulation, alert triage, and
clear incident documentation.