# Init Containers - Initialization Logic

## 📚 Overview
Init Containers main application containers se pehle run hote hain. Ye initialization tasks, setup, aur prerequisites handle karte hain.

## 🎯 Use Cases
- Database migrations
- Configuration setup
- Dependency checks
- File downloads
- Permission setup

## 📖 Key Features
- **Sequential execution** - One after another
- **Must complete successfully** - Before main containers start
- **Shared volumes** - With main containers
- **Same resources** - Network, storage access

## 🔧 Common Patterns

### 1. **Database Migration**
```yaml
initContainers:
- name: db-migration
  image: spicybiryaniwala.shop/migrator:latest
  command: ["migrate", "up"]
  env:
  - name: DB_URL
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: url
```

### 2. **Configuration Setup**
```yaml
initContainers:
- name: config-setup
  image: busybox
  command: ["sh", "-c"]
  args:
  - |
    echo "Setting up configuration..."
    cp /config-template/* /shared-config/
    chmod 644 /shared-config/*
  volumeMounts:
  - name: shared-config
    mountPath: /shared-config
```

### 3. **Dependency Check**
```yaml
initContainers:
- name: wait-for-db
  image: busybox
  command: ["sh", "-c"]
  args:
  - |
    until nc -z postgres-service 5432; do
      echo "Waiting for database..."
      sleep 2
    done
```

## 🔗 Related Topics
- [Multi-Pod Design Patterns](../multi-pods-design-pattern/)
- [Configuration Management](../configure-application/)

---

**Next:** [Multi-Pod Design Patterns](../multi-pods-design-pattern/) - Container Collaboration