#!/usr/bin/env bash
set -euo pipefail
trap 'echo "Interrupted exiting"; exit 130' SIGINT SIGTERM

###############################################################################
# 0.  Defaults & constants
###############################################################################
export TYPE="${TYPE:-mainnet}"          # mainnet unless user overrides
export RUN_CONFIGURE="${RUN_CONFIGURE:-once}"   # skip | once | always | default: once | future feature: on_change 
export PYTHONUNBUFFERED=1               # flush ansible output live
export CMT_LOG_LEVEL=p2p:none,pex:error
export NAMADA_CMT_STDOUT=true

DATA_HOME="/home/namada/.local/share"
CONFIG_MARK="${DATA_HOME}/namada/.configured.ok"

###############################################################################
# 1.  Function to run the Ansible role idempotently
###############################################################################
run_ansible() {
  echo "Running Ansible bootstrap..."
  ANSIBLE_CALLBACK_RESULT_FORMAT=yaml \
  ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3 \
  ansible-playbook /ansible/bootstrap.yml -i localhost, -c local
  # touch marker only if playbook succeeded
  touch "${CONFIG_MARK}"
}

###############################################################################
# 2.  Run bootstrap only as root, then drop privileges
###############################################################################
if [ "$(id -u)" = 0 ]; then
  case "$RUN_CONFIGURE" in
    skip)
      echo "⚠️  RUN_CONFIGURE=skip; bootstrap skipped."
      ;;
    once)
      if [ -f "${CONFIG_MARK}" ]; then
        echo "✔ Configuration already present; skipping bootstrap."
      else
        run_ansible
      fi
      ;;
    always)
      run_ansible
      ;;
    *)
      echo "❌ Unknown RUN_CONFIGURE value: '$RUN_CONFIGURE'"
      exit 1
      ;;
  esac

  # ensure namada user owns its data directory
  chown -R namada:namada "${DATA_HOME}"
  chown -R namada:namada /home/namada/.masp-params
  exec gosu namada "$0" "$@"            # re‑exec this script as UID 1000
fi

###############################################################################
# 3.  Chain‑ID mapping (runs as unprivileged 'namada' user)
###############################################################################
case "$TYPE" in
  mainnet)
    export NAMADA_LEDGER__CHAIN_ID="namada.5f5de2dd1b88cba30586420"
    ;;
  housefire-testnet)
    export NAMADA_LEDGER__CHAIN_ID="housefire-alpaca.cc0d3e0c033be"
    ;;
  *)
    echo "❌ Unknown TYPE: '$TYPE'"
    exit 1
    ;;
esac
echo "➡ Using chain-id: $NAMADA_LEDGER__CHAIN_ID"

###############################################################################
# 4.  Default command (ledger run) if user gave none
###############################################################################
[ "$#" -eq 0 ] && set -- ledger run

exec /usr/local/bin/namada "$@"
