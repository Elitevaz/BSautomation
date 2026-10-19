$instances = @(
    @{
        Name = "Pie64"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = "--instance Pie64"
    },
    @{
        Name = "Pie64_1"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = "--instance Pie64_1"
    },
    @{
        Name = "Pie64_6"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = "--instance Pie64_6"
    },
    @{
        Name = "Pie64_7"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = "--instance Pie64_7"
    },
    @{
        Name = "Pie64_8"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = "--instance Pie64_8"
    },
    @{
        Name = "Pie64_9"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = "--instance Pie64_9"
    }
)

$logPath = "C:\BlueStacks\Watchdog\watchdog-process-only.log"
$pollIntervalSeconds = 60
$restartDelaySeconds = 30

New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp $Message"
}

function Get-InstanceProcess {
    param([string]$InstanceName)

    $escapedInstanceName = [regex]::Escape($InstanceName)

    $instanceArgumentPattern =
        '(?i)(?:^|\s)--instance\s+(?:"?' +
        $escapedInstanceName +
        '"?)(?=\s|$)'

    Get-CimInstance Win32_Process -Filter "Name = 'HD-Player.exe'" -ErrorAction Stop |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine -match $instanceArgumentPattern
        }
}

Write-Log "Process-only watchdog started."

while ($true) {
    foreach ($instance in $instances) {
        try {
            $running = Get-InstanceProcess -InstanceName $instance.Name |
                Select-Object -First 1
        }
        catch {
            Write-Log "Could not inspect $($instance.Name). Skipping this cycle: $($_.Exception.Message)"
            continue
        }

        if ($null -eq $running) {
            Write-Log "$($instance.Name) is not running. Starting it."

            try {
                Start-Process `
                    -FilePath $instance.File `
                    -ArgumentList $instance.Args `
                    -WorkingDirectory (Split-Path $instance.File) `
                    -ErrorAction Stop

                Start-Sleep -Seconds $restartDelaySeconds
            }
            catch {
                Write-Log "Failed to start $($instance.Name): $($_.Exception.Message)"
            }
        }
    }

    Start-Sleep -Seconds $pollIntervalSeconds
}
