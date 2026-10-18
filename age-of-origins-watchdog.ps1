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
$hungChecksBeforeRecovery = 2
$hungCheckCounts = @{}


function Write-Log {
    param([string]$Message)
    Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
}

if (-not ("Watchdog.NativeMethods" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace Watchdog
{
    public static class NativeMethods
    {
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SendMessageTimeout(
            IntPtr hWnd,
            uint Msg,
            IntPtr wParam,
            IntPtr lParam,
            uint fuFlags,
            uint uTimeout,
            out IntPtr lpdwResult);
    }
}
'@
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

function Test-InstanceWindowResponsive {
    param(
        [Parameter(Mandatory)]
        $InstanceProcess
    )

    try {
        $process = Get-Process -Id $InstanceProcess.ProcessId -ErrorAction Stop
        $windowHandle = $process.MainWindowHandle

        if ($windowHandle -eq [IntPtr]::Zero) {
            return $false
        }

        $messageResult = [IntPtr]::Zero

        $callResult = [Watchdog.NativeMethods]::SendMessageTimeout(
            $windowHandle,
            0,
            [IntPtr]::Zero,
            [IntPtr]::Zero,
            0x0002,
            5000,
            [ref]$messageResult
        )

        return ($callResult -ne [IntPtr]::Zero)
    }
    catch {
        return $false
    }
}

while ($true) {
    foreach ($instance in $instances) {
        $running = Get-InstanceProcess -InstanceName $instance.Name |
            Select-Object -First 1

        if (-not $running) {
            $hungCheckCounts[$instance.Name] = 0

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
        elseif (Test-InstanceWindowResponsive -InstanceProcess $running) {
            if (
                $hungCheckCounts.ContainsKey($instance.Name) -and
                $hungCheckCounts[$instance.Name] -gt 0
            ) {
                Write-Log "$($instance.Name) is responsive again. Resetting hang counter."
            }

            $hungCheckCounts[$instance.Name] = 0
        }
        else {
            $failureCount = 0

            if ($hungCheckCounts.ContainsKey($instance.Name)) {
                $failureCount = [int]$hungCheckCounts[$instance.Name]
            }

            $failureCount++
            $hungCheckCounts[$instance.Name] = $failureCount

            if ($failureCount -eq 1) {
                Write-Log "$($instance.Name) window is unresponsive. Failure 1 of $hungChecksBeforeRecovery."
            }
            elseif ($failureCount -eq $hungChecksBeforeRecovery) {
                Write-Log "$($instance.Name) window is unresponsive twice. Recovery would start now; detection-only mode is enabled."
            }
        }
    }

    Start-Sleep -Seconds 60
}
