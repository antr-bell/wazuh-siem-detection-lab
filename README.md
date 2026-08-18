Cloud SIEM Incident Response & Threat Simulation Lab
Executive Summary & Core Objective

The primary objective of this project is to simulate a realistic Incident Response (IR) and alert triage lifecycle for common cyber threat vectors. By standing up a controlled, cloud-hosted security lab combining a SIEM (Wazuh) and a Network Intrusion Detection System (Suricata) on AWS, this project focuses on capturing, triaging, investigating, and tuning detections for simulated real-world attacks such as brute-force authentication attempts and network intrusion indicators.
1. Lab Architecture & Rapid Provisioning

To ensure a repeatable, cost-effective testing ground, infrastructure deployment and teardown are fully automated via code.

    Infrastructure as Code (Terraform): Automatically provisions the AWS EC2 instance and injects configuration scripts to keep deployment fast and repeatable.

    Component Version Pinning: Hardcodes specific package and dependency versions in user-data scripts to prevent breaking updates during automated provisioning.

    SIEM & Monitoring Stack:

        Wazuh Manager & Dashboard: Deployed in Docker containers for centralized log management, health visualization, and Dev Tools access.

        Wazuh Agent: Native host agent monitoring system logs, authentication logs, and network telemetry.

        Suricata: Configured to monitor network flows and output structured JSON alerts (eve.json) into the SIEM pipeline.

2. Simulated Threat Scenarios & Attack Vectors

Out-of-the-box cloud and SIEM defaults often suppress telemetry or block inbound test traffic. To effectively simulate common attacks, default restrictions were intentionally and safely tuned:

    SSH Brute-Forcing: Permitted controlled inbound SSH traffic to simulate multi-source authentication failure spikes, testing Wazuh's rule engine for brute-force detection thresholds.

    Network Intrusion & Flow Suricata Alerts: Triggered network-based signature rules to evaluate how Suricata logs integrate with host-level SIEM alerts.

    Log Ingestion & System Anomaly Monitoring: Monitored critical system paths (/var/log/auth.log, /var/log/syslog, command execution outputs) to capture post-exploitation indicators or unauthorized changes.

3. Incident Triage & Investigation Workflow

Simulating an attack is only half the battle; the core of the project centers on how an analyst processes the resulting telemetry:

    Ingestion & Alert Triage: Reviewing incoming Wazuh rule alerts and sorting them by severity level to identify anomalous behavior.

    Contextual Cross-Referencing: Avoiding reaction to isolated alerts by manually checking raw logs (auth.log, syslog) to verify whether an event represents administrative maintenance, automated tooling, or malicious intent.

    False Positive Filtering & Noise Reduction: Isolating baseline operational chatter from genuine Indicators of Compromise (IoCs).

    Queue & Buffer Management: Handling event spikes and backlog congestion by adjusting agent queue parameters and utilizing Wazuh Dev Tools/API calls to clear stale states and prevent disk bloat.

4. Detection Engineering & Rule Tuning

Many common attacks slip past default rules because default security baselines are intentionally conservative. Remediation involved:

    Threshold Tuning: Adjusting trigger counts for authentication failures to minimize alert latency.

    Path Alignment: Ensuring custom log formats (like Suricata's JSON output) map cleanly to the SIEM parser.

    Overcoming Security Presets: Striking the right balance between hardened default security policies and open testing boundaries necessary to capture malicious signatures during simulation.

5. Sample Incident Report: SSH Brute-Force Attack

    Incident ID: INC-SIM-01-SSH

    Attack Vector: Credential Brute-Forcing (SSH Service)

    Detection Source: Wazuh Rule ID 5710 (Multiple authentication failures) + Suricata Flow Logs

    Severity: Medium / High

    Triage Analysis:

        Observation: A rapid surge of failed login attempts originated from an external testing source targeting port 22.

        Verification: Cross-referenced with /var/log/auth.log to confirm repeated Invalid user and Failed password entries. System verification confirmed no successful login sessions were established.

    Remediation & Response:

        Verified firewall rule behavior to ensure dropping capabilities.

        Tuned authentication failure thresholds to ensure rapid alerting without triggering analyst fatigue from routine noise.


## Lessons Learned & Project Takeaways

1. **Explicit Component Version Matching in User Data**
   Hardcoding explicit software and component versions within the cloud-init user data script prevents unexpected auto-upgrades or breaking dependency changes during automated node provisioning, ensuring a reproducible environment across rebuilds.

2. **Automated Infrastructure Provisioning via Terraform**
   Integrating bootstrapping steps and configuration templates directly into Terraform user data dramatically streamlined the deployment and teardown lifecycle, minimizing manual SSH intervention and reducing cloud expenditure during testing.

3. **Queue Management & Alert Noise Suppression**
   Managing backlog congestion required careful handling of agent event thresholds and queue configurations. Adjusting buffer sizes and utilizing Wazuh API/Dev Tools to purge stale states prevented disk bloat and streamlined alert visibility.

4. **Overcoming Default Security Presets for Attack Simulation**
   Default out-of-the-box Wazuh and platform policies are often too restrictive or suppress telemetry for common vector scenarios. Explicitly tuning rule levels, firewall allowances, and log ingestion paths (such as enabling granular auth tracking for SSH brute-forcing) was necessary to successfully capture and log basic simulated attack traffic.


Conclusion & Investigation Methodology

This project demonstrated that deploying a SIEM (Wazuh) alongside network monitoring (Suricata) in a cloud-hosted environment (AWS) provides comprehensive visibility into security events. However, a tool is only as effective as the analyst tuning it.
Key Lessons Learned in Report Writing & Investigation

    Contextualizing Raw Alerts (Investigation over Assumption): Raw alerts without system context lead to false conclusions. Every suspicious event—such as repeated authentication failures or unusual SUID binaries—must be cross-referenced with system logs (auth.log, syslog) to determine if it stems from routine administrative tasks, automated background jobs, or an actual compromise.

    Rigorous False Positive Identification: Out-of-the-box SIEM rules often flag standard system processes or administrative administrative activity as threats. Analysts must document baseline behavior to isolate noise from signal, ensuring that legitimate operational traffic does not obscure real indicators of compromise (IoCs).

    Targeted Rule Tuning: Merely capturing alerts is insufficient; analysts must actively refine detection logic. Tuning thresholds, suppressing chronic false positives, and writing custom rules for specific threat vectors (like brute-force thresholds or precise Suricata signatures) prevent alert fatigue and improve Mean Time to Detect (MTTD).

    Actionable Reporting Structure: Effective incident reporting requires clear categorization—moving from executive summaries and technical timelines to specific remediation steps and rule adjustments. A strong report highlights not just what happened, but why the detection mechanism succeeded or failed and how to prevent future blind spots.