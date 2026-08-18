{\rtf1\ansi\ansicpg1252\cocoartf2868
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 #!/usr/bin/env bash\
#\
# 03_malicious_file_fim.sh\
# Simulates: Malicious File Creation (EICAR Standard Test File)\
# MITRE ATT&CK: T1204.002 (User Execution: Malicious File) - Execution\
# Detection layer: Wazuh FIM / syscheck, real-time monitoring\
#\
# Usage: ./03_malicious_file_fim.sh\
#\
# PREREQUISITE (one-time setup, see infrastructure/wazuh-config/ossec.conf):\
#   <syscheck> must include a <directories realtime="yes"> entry for the\
#   target directory below, or this will only be caught on the next\
#   scheduled scan (default: every 12 hours) instead of instantly.\
#\
# Uses the industry-standard EICAR test string - a safe, universally\
# recognized AV/IDS test signature. This is NOT real malware.\
\
set -euo pipefail\
\
TARGET_DIR="$\{HOME\}/Downloads"\
MANAGER_CONTAINER="single-node-wazuh.manager-1"\
EICAR_STRING='X5O!P%@AP[4\\PZX54(P^)7CC)7\}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'\
FILENAME="invoice_details_urgent_$(date +%s).exe"\
\
echo "=== Malicious File / FIM Simulation ==="\
mkdir -p "$\{TARGET_DIR\}"\
\
echo "Writing EICAR test file to $\{TARGET_DIR\}/$\{FILENAME\}..."\
echo "$\{EICAR_STRING\}" > "$\{TARGET_DIR\}/$\{FILENAME\}"\
\
echo ""\
echo "=== File created. Waiting for real-time FIM to process... ==="\
sleep 3\
\
echo ""\
echo "=== Verifying alert in Wazuh ==="\
docker exec -it "$\{MANAGER_CONTAINER\}" grep -i -A15 "$\{FILENAME\}" \\\
  /var/ossec/logs/alerts/alerts.json | tail -30\
\
echo ""\
echo "Done. File left in place at $\{TARGET_DIR\}/$\{FILENAME\} for evidence/screenshot purposes."\
echo "Remove manually when finished: rm $\{TARGET_DIR\}/$\{FILENAME\}"}