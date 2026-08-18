{\rtf1\ansi\ansicpg1252\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/usr/bin/env bash\
#\
# 04_persistence_account.sh\
# Simulates: Unauthorized Local Account Creation + Privilege Escalation\
# MITRE ATT&CK: T1136.001 (Create Account: Local Account) - Persistence\
#               T1548 (Abuse Elevation Control Mechanism) - Privilege Escalation\
# Detection layer: Wazuh "new group/user added" system rules\
#\
# Usage: sudo ./04_persistence_account.sh\
#\
# Simulates an attacker establishing a persistent, privileged backdoor\
# account rather than a throwaway one - creates a group, a user in that\
# group, then escalates the user into the sudo group.\
\
set -euo pipefail\
\
BACKDOOR_GROUP="backdoorgrp"\
BACKDOOR_USER="backdooruser"\
MANAGER_CONTAINER="single-node-wazuh.manager-1"\
\
if [[ "$\{EUID\}" -ne 0 ]]; then\
  echo "This script must be run with sudo/root." >&2\
  exit 1\
fi\
\
echo "=== Persistence via Account Creation Simulation ==="\
\
echo "Step 1: Creating group $\{BACKDOOR_GROUP\}..."\
groupadd "$\{BACKDOOR_GROUP\}" 2>/dev/null || echo "Group already exists, continuing."\
\
echo "Step 2: Creating user $\{BACKDOOR_USER\}..."\
useradd -m -s /bin/bash -g "$\{BACKDOOR_GROUP\}" "$\{BACKDOOR_USER\}" 2>/dev/null || echo "User already exists, continuing."\
\
echo "Step 3: Setting a temporary password..."\
echo "$\{BACKDOOR_USER\}:TempPass123!" | chpasswd\
\
echo "Step 4: Escalating - adding $\{BACKDOOR_USER\} to the sudo group..."\
usermod -aG sudo "$\{BACKDOOR_USER\}"\
\
echo ""\
echo "=== Simulation complete. Waiting for log propagation... ==="\
sleep 3\
\
echo ""\
echo "=== Verifying alert in Wazuh ==="\
docker exec -it "$\{MANAGER_CONTAINER\}" grep -i -A15 "$\{BACKDOOR_USER\}\\|$\{BACKDOOR_GROUP\}\\|new group\\|new user" \\\
  /var/ossec/logs/alerts/alerts.json | tail -30\
\
echo ""\
read -rp "Remove the test account and group now? [y/N] " CONFIRM\
if [[ "$\{CONFIRM\}" =~ ^[Yy]$ ]]; then\
  userdel -r "$\{BACKDOOR_USER\}" 2>/dev/null || true\
  groupdel "$\{BACKDOOR_GROUP\}" 2>/dev/null || true\
  echo "Test account and group removed."\
else\
  echo "Leaving account in place. Remove manually with:"\
  echo "  userdel -r $\{BACKDOOR_USER\} && groupdel $\{BACKDOOR_GROUP\}"\
fi}