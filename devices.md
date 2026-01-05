# Test Devices Connection Info

## Device 1: Samsung Galaxy S8 (SM-G950F)
- **ADB Serial**: `ce0317133a9ad0190c`
- **SSH Port**: `8022` (forwarded)
- **Username**: `u0_a413`
- **Password**: `termux123`

```bash
# ADB Forward
adb -s ce0317133a9ad0190c forward tcp:8022 tcp:8022

# SSH Connect
ssh u0_a413@localhost -p 8022

# Python
ssh_exec(cmd, port=8022, user='u0_a413', password='termux123')
```

## Device 2: Samsung Galaxy Tab S9 FE+ (SM-X716B)
- **ADB Serial**: `R52Y100VWGM`
- **SSH Port**: `8023` (forwarded to 8022)
- **Username**: `u0_a340`
- **Password**: `termux123`

```bash
# ADB Forward
adb -s R52Y100VWGM forward tcp:8023 tcp:8022

# SSH Connect
ssh u0_a340@localhost -p 8023

# Python
ssh_exec(cmd, port=8023, user='u0_a340', password='termux123')
```

## Quick SSH Helper

```python
import paramiko

def ssh_exec(cmd, port=8022, user='u0_a413', password='termux123'):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect('localhost', port=port, username=user, password=password, timeout=10)
    stdin, stdout, stderr = client.exec_command(cmd)
    out = stdout.read().decode()
    err = stderr.read().decode()
    client.close()
    return out, err

# Device 1
out, err = ssh_exec('whoami', port=8022, user='u0_a413')

# Device 2
out, err = ssh_exec('whoami', port=8023, user='u0_a340')
```
