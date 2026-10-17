# C:\BlueStacks\Watchdog\BlueStacks-Watchdog.ps1

$instances = @(
    @{
        Name = "BS-01"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance "Nougat64_1"'
    },
    @{
        Name = "BS-02"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance "Nougat64_2"'
    },
    @{
        Name = "BS-03"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance "Nougat64_3"'
    },
    @{
        Name = "BS-04"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance "Nougat64_4"'
    },
    @{
        Name = "BS-05"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance "Nougat64_5"'
    },
    @{
        Name = "BS-06"
        File = "C:\Program Files\BlueStacks_nxt\HD-Player.exe"
        Args = '--instance "Nougat64_6"'
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

    Get-CimInstance Win32_Process -Filter "Name = 'HD-Player.exe'" |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine -match [regex]::Escape($InstanceName)
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
