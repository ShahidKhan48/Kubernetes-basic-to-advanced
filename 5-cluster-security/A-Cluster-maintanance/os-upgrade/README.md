# OS Upgrade Management

## 📚 Overview
Operating system upgrades aur node maintenance procedures.

## 🎯 OS Upgrade Process

### Pre-upgrade Steps
```bash
# Check current OS version
lsb_release -a
uname -r

# Check available updates
apt list --upgradable
apt-cache policy

# Backup system
tar -czf /backup/system-$(date +%Y%m%d).tar.gz /etc /var/lib/kubelet
```

### Node Upgrade Procedure
```bash
# 1. Drain node
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# 2. Update packages
apt-get update
apt-get upgrade -y

# 3. Reboot if kernel updated
if [ -f /var/run/reboot-required ]; then
  reboot
fi

# 4. Uncordon node
kubectl uncordon <node-name>
```

### Automated OS Updates
```yaml
# Unattended upgrades configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: unattended-upgrades-config
data:
  50unattended-upgrades: |
    Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
    };
    Unattended-Upgrade::AutoFixInterruptedDpkg "true";
    Unattended-Upgrade::MinimalSteps "true";
    Unattended-Upgrade::Automatic-Reboot "false";
```

## 📋 Best Practices
- Schedule maintenance windows
- Test updates in staging
- Monitor system stability
- Coordinate with application teams