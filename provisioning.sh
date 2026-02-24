#!/bin/bash

SERVER_LIST="servers.txt"
SSH_USER="ubuntu"
SSH_KEY="$HOME/.ssh/id_rsa_baremetal"

# Input password ubuntu (fallback)
read -s -p "Masukkan password ubuntu (untuk server tanpa key): " UBUNTU_PASS
echo ""

# Input password devops (jika user belum ada)
read -s -p "Masukkan password devops (dipakai jika user belum ada): " DEVOPS_PASS
echo ""

# Input PUBLIC KEY untuk devops
echo "Paste PUBLIC KEY untuk user devops (akhiri dengan ENTER):"
read -r DEVOPS_PUBKEY

for HOST in $(cat "$SERVER_LIST"); do
  echo "========================================="
  echo "Processing $HOST"
  echo "========================================="

  # Test SSH key login dulu
  ssh -o BatchMode=yes -o ConnectTimeout=5 -i "$SSH_KEY" "$SSH_USER@$HOST" "echo ok" >/dev/null 2>&1
  KEY_STATUS=$?

  if [ $KEY_STATUS -eq 0 ]; then
      echo "✅ Login pakai SSH key"
      SSH_CMD="ssh -tt -i $SSH_KEY -o StrictHostKeyChecking=no $SSH_USER@$HOST"
  else
      echo "⚠️  Key gagal, pakai password"
      SSH_CMD="SSHPASS=\"$UBUNTU_PASS\" sshpass -e ssh -tt \
        -o StrictHostKeyChecking=no \
        -o PreferredAuthentications=password \
        -o PubkeyAuthentication=no \
        $SSH_USER@$HOST"
  fi

  eval $SSH_CMD \"'
    set -e

    sudo mkdir -p /etc/ssh/sshd_config.d

    sudo tee /etc/ssh/sshd_config.d/01-rule.conf >/dev/null << \"EOF\"
PasswordAuthentication yes
PubkeyAuthentication yes

Match User ubuntu
    PasswordAuthentication no
    PubkeyAuthentication yes

Match User devops
    PasswordAuthentication yes
    PubkeyAuthentication yes
EOF

    sudo sshd -t
    sudo systemctl restart ssh

    # Create user if not exists
    if id devops >/dev/null 2>&1; then
        echo \"User devops sudah ada\"
    else
        echo \"Membuat user devops\"
        sudo useradd -m -s /bin/bash devops
        echo \"devops:$DEVOPS_PASS\" | sudo chpasswd
    fi

    # Sudoers
    sudo usermod -aG sudo devops || true
    echo \"devops ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/devops >/dev/null
    sudo chmod 440 /etc/sudoers.d/devops
    sudo visudo -cf /etc/sudoers.d/devops

    # SSH key setup
    sudo install -m 700 -d /home/devops/.ssh

    # Append key only if not exists
    if ! sudo grep -qxF \"$DEVOPS_PUBKEY\" /home/devops/.ssh/authorized_keys 2>/dev/null; then
        echo \"$DEVOPS_PUBKEY\" | sudo tee -a /home/devops/.ssh/authorized_keys >/dev/null
    fi

    sudo chown -R devops:devops /home/devops/.ssh
    sudo chmod 600 /home/devops/.ssh/authorized_keys

    echo \"✅ Server selesai\"
  '\"

  if [ $? -eq 0 ]; then
      echo "🎉 SUCCESS: $HOST"
  else
      echo "❌ FAILED: $HOST"
  fi

  echo ""
done
