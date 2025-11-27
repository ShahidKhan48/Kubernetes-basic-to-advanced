# Command & Arguments in Kubernetes

## 📚 Overview
Container command aur arguments configuration in Kubernetes pods.

## 🎯 Command vs Arguments
- **command**: Container entrypoint override
- **args**: Arguments passed to command
- **Dockerfile**: CMD aur ENTRYPOINT relationship

## 📖 Basic Examples

### Command Override
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: command-demo
spec:
  containers:
  - name: demo
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "echo Hello World && sleep 30"]
```

### Multiple Commands
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-command
spec:
  containers:
  - name: app
    image: ubuntu:20.04
    command: ["/bin/bash"]
    args:
    - -c
    - |
      echo "Starting application..."
      apt-get update
      apt-get install -y curl
      echo "Setup completed"
      sleep infinity
```

## 🔧 Environment Variables in Commands
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-command
spec:
  containers:
  - name: app
    image: busybox
    env:
    - name: MESSAGE
      value: "Hello from Kubernetes"
    - name: USER_NAME
      value: "spicybiryaniwala"
    command: ["/bin/sh"]
    args: ["-c", "echo $MESSAGE from $USER_NAME"]
```

## 📋 Best Practices
- Use specific commands for debugging
- Combine with environment variables
- Handle signals properly
- Use exec form for better signal handling