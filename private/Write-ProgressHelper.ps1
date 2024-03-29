function Write-ProgressHelper {
    # thanks adam!
    # https://www.adamtheautomator.com/building-progress-bar-powershell-scripts/
    param (
        [int]$StepNumber,
        [string]$Activity,
        [string]$Message,
        [int]$TotalSteps,
        [Alias("NoProgress")]
        [switch]$ExcludePercent
    )

    $caller = (Get-PSCallStack)[1].Command

    if (-not $Activity) {
        $Activity = switch ($caller) {
            "Export-DbsInstance" {
                "Performing Instance Export for $instance"
            }
            default {
                "Executing $caller"
            }
        }
    }

    if ($ExcludePercent) {
        Write-Progress -Activity $Activity -Status $Message
    } else {
        if (-not $TotalSteps -and $caller -ne '<ScriptBlock>') {
            $TotalSteps = ([regex]::Matches((Get-Command -Module dbatools -Name $caller).Definition, "Write-ProgressHelper")).Count
        }
        if (-not $TotalSteps) {
            $percentComplete = 0
        } else {
            $percentComplete = ($StepNumber / $TotalSteps) * 100
        }
        Write-Progress -Activity $Activity -Status $Message -PercentComplete $percentComplete
    }
}