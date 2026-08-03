# CheckPort

A simple PowerShell script that continuously monitors whether a TCP port is reachable on a given host, with optional file logging.

## Features

- Validates the target IP address and port before running
- Pings the target once to confirm it's online before starting the monitoring loop
- Repeatedly checks TCP port reachability at a configurable interval
- Logs status changes (port down / port back up) to a daily log file
- Prints a summary of reachable vs. unreachable checks when the script exits

## Requirements

- PowerShell **4.0** or later
- **NetTCPIP** module (built into Windows 8.1 / Windows Server 2012 R2 and later)
- Windows only — `Test-NetConnection` is not available on Linux/macOS, even under PowerShell 7

## Usage

```powershell
.\CheckPort.ps1 -Target "192.168.1.10" -Port 80 -EnableLogging -LogPath "C:\Logs\CheckPort"
```

The script runs in an infinite loop, checking the port at the configured interval. Stop it with `Ctrl+C` — a summary will still be printed on exit.

## Parameters

| Parameter | Required | Default | Description |
|---|---|---|---|
| `Target`  | Yes | — | The IP address to check. Must be a valid IPv4 address. |
| `Port`  | Yes | — | The TCP port to check (1–65535). |
| `EnableLogging`  | No | Off | Enables writing status changes to a log file. |
| `CheckInterval`  | No | `60` | Seconds to wait between each check. |
| `LogPath`  | No | `Logs` folder next to the script | Directory where the daily log file is stored. |

## Example

```powershell
.\CheckPort.ps1 -Target "10.0.0.5" -Port 443 -EnableLogging -CheckInterval 30
```

Checks port 443 on `10.0.0.5` every 30 seconds and logs status changes to `.\Logs\<date>.log`.
