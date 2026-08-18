{\rtf1\ansi\ansicpg1252\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/usr/bin/env bash\
#\
# 02_unauthorized_sudo.sh\
# Simulates: Unauthorized Privilege Escalation Attempt (Sudo)\
# MITRE ATT&CK: T1548.003 (Sudo and Sudo Caching) - Privilege Escalation\
# Detection layer: Wazuh sudo rule group (via /var/log/auth.log)\
#\
# Usage: sudo ./02_unauthorized_sudo.sh\
#\
# Creates a temporary, deliberately unprivileged user, attempts a sudo command\
# as that user (which will fail and log), then tears the account down.\
\
set -euo pipefail\
\
TEST_USER="testuser"\
MANAGER_CONTAINER="single-node-wazuh.manager-1"\
\
if [[ "$\{EUID\}" -ne 0 ]]; then\
  echo "This script must be run with sudo/root." >&2\
  exit 1\
fi\
\
echo "=== Unauthorized Sudo Attempt Simulation ==="\
\
echo "Creating test account: $\{TEST_USER\}..."\
useradd -m -s /bin/bash "$\{TEST_USER\}" 2>/dev/null || echo "User already exists, continuing."\
\
echo ""\
echo "Attempting sudo as $\{TEST_USER\} (expected to FAIL - this is the point)..."\
su - "$\{TEST_USER\}" -c "sudo whoami" 2>&1 || true\
\
echo ""\
echo "=== Simulation complete. Waiting for log propagation... ==="\
sleep 3\
\
echo ""\
echo "=== Verifying alert in Wazuh ==="\
docker exec -it "$\{MANAGER_CONTAINER\}" grep -i "not in the sudoers\\|sudo" \\\
  /var/ossec/logs/alerts/alerts.json | tail -10\
\
echo ""\
read -rp "Remove the test account ($\{TEST_USER\}) now? [y/N] " CONFIRM\
if [[ "$\{CONFIRM\}" =~ ^[Yy]$ ]]; then\
  userdel -r "$\{TEST_USER\}" 2>/dev/null || true\
  echo "Test account removed."\
else\
  echo "Leaving $\{TEST_USER\} in place. Remove manually with: userdel -r $\{TEST_USER\}"\
fi}