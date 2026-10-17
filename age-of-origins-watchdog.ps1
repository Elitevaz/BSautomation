$instances = @(
    @{
        Name = "Pie64_6"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe" 
        Args = '--instance Pie64_6'
    },
    @{
        Name = "Pie64_7"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance Pie64_7'
    },
    @{
        Name = "Pie64"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance Pie64'
    },
    @{
        Name = "Pie64_1"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance Pie64_1'
    },
    @{
        Name = "Pie64_8"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance Pie64_8'
    },
    @{
        Name = "Pie64_9"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance Pie64_9'
    }
)

$logPath = "C:\BlueStacks\Watchdog\watchdog.log"
New-Item -ItemType Directory -Force -Path (Split-Path $logPath) | Out-Null

function Write-Log {
    param([string]$Message)
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

function Get-InstanceProcess {
    param([string]$InstanceName)

    # Match the complete value following --instance, not merely text
    # that happens to contain the instance name.
    $escapedInstanceName = [regex]::Escape($InstanceName)

    $instanceArgumentPattern =
        '(?i)(?:^|\s)--instance\s+(?:"?' +
        $escapedInstanceName +
        '"?)(?=\s|$)'

    Get-CimInstance Win32_Process -Filter "Name = 'HD-Player.exe'" |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine -match $instanceArgumentPattern
        }
}


while ($true) {
    foreach ($instance in $instances) {
        $running = Get-InstanceProcess -InstanceName $instance.Name

        if (-not $running) {
            Write-Log "$($instance.Name) is not running. Starting it."

            try {
                Start-Process `
                    -FilePath $instance.File `
                    -ArgumentList $instance.Args `
                    -WorkingDirectory (Split-Path $instance.File)

                Start-Sleep -Seconds 30
            }
            catch {
                Write-Log "Failed to start $($instance.Name): $($_.Exception.Message)"
            }
        }
    }

    Start-Sleep -Seconds 60
}
