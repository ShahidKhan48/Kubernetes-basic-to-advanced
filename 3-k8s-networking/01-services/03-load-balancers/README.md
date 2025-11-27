# Load Balancers - External Traffic Management

## Overview
Load balancers provide external access to services with advanced traffic distribution, health checking, and cloud provider integration.

## Load Balancer Types

### Layer 4 (Network Load Balancer)
- **TCP/UDP load balancing**
- **High performance**: Low latency, high throughput
- **IP preservation**: Client IP passthrough
- **Health checks**: TCP-based monitoring

### Layer 7 (Application Load Balancer)
- **HTTP/HTTPS load balancing**
- **Content-based routing**: Path and host routing
- **SSL termination**: Certificate management
- **Advanced features**: WebSocket, HTTP/2 support

## Cloud Provider Integration

### AWS Load Balancers
- **Network Load Balancer (NLB)**: Layer 4, high performance
- **Application Load Balancer (ALB)**: Layer 7, feature-rich
- **Classic Load Balancer**: Legacy, basic features

### Google Cloud Load Balancing
- **Network Load Balancing**: Regional, high performance
- **HTTP(S) Load Balancing**: Global, content-based routing
- **Internal Load Balancing**: Private network access

### Azure Load Balancer
- **Basic Load Balancer**: Simple load balancing
- **Standard Load Balancer**: Advanced features
- **Application Gateway**: Layer 7 with WAF

## Key Features

### Health Checks
- **HTTP health checks**: Application-level monitoring
- **TCP health checks**: Connection-level monitoring
- **Custom health check paths**: Application-specific endpoints

### SSL/TLS Termination
- **Certificate management**: Automatic provisioning
- **SSL policies**: Security configuration
- **SNI support**: Multiple certificates

### Traffic Distribution
- **Round robin**: Equal distribution
- **Least connections**: Route to least busy
- **IP hash**: Consistent routing
- **Weighted**: Capacity-based distribution

## Best Practices

1. **Use appropriate load balancer type for workload**
2. **Configure proper health checks**
3. **Implement SSL termination at load balancer**
4. **Monitor load balancer performance and costs**
5. **Use internal load balancers for private services**
6. **Configure appropriate timeouts and thresholds**
7. **Implement proper security groups and access controls**