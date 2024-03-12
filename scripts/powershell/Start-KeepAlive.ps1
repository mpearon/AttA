<#
	.NOTES
		Author:     Matthew A. Pearon
		Date:       2024-03-12 15:00
		CoreCompat: false
	.COMPONENT
		Start-KeepAlive, SendKeys
	.SYNOPSIS
		Start-KeepAlive ensures that an interactive session stays active
	.DESCRIPTION
		Start-KeepAlive leverages System.Windows.Forms to determine whether or
		not the session has been inactive.  In the even that the cursor has not
		moved in a preset timeframe, the F14 key will be sent.
	.PARAMETER hours
		This allows the user to specify the number of hours to keep the
		session active. Can be used in concert with the minutes parameter.
	.PARAMETER minutes
		This allows the user to specify the number of minutes to keep the
		session active.  Can be used in concert with the hours parameter.
	.PARAMETER until
		This allows the user to specify a specific end time. Can be used with
		the hours or minutes parameters.
	.PARAMETER quickPoll
		This switch will force the script to evaluate/update at a 1 second
		interval.
	.EXAMPLE
		./Start-KeepAlive.ps1 -until 16:00
	.EXAMPLE
		./Start-KeepAlive.ps1 -hours 2 -minutes 30
	.EXAMPLE
		./Start-KeepAlive.ps1 -hours 1.5
	.LINK
		https://github.com/mpearon
	.LINK
		https://twitter.com/@mpearon
#>
[CmdletBinding( DefaultParameterSetName = 'until' )]
Param(
	[Parameter( ParameterSetName = 'hourMinute' )][double]$hours = 0,
    [Parameter( ParameterSetName = 'hourMinute' )][double]$minutes = 0,
	[Parameter( ParameterSetName = 'until' )]$until,
	[switch]$quickPoll
)
[Void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
$cursor = [System.Windows.Forms.Cursor]
$initialPosition = $null
switch( $PSCmdlet.ParameterSetName ){
	'hourMinute' 	{ $endDateTime = (Get-Date).AddHours($hours).AddMinutes($minutes) }
	'until'			{ $endDateTime = (Get-Date $until) }
}
$initialDuration = ( $endDateTime - (Get-Date) )
Write-Host ( 'Keep-Alive will expire at {0}' -f ( Get-Date $endDateTime -f 'yyyy-MM-dd HH:mm:ss' ) )
Write-Progress -PercentComplete 100 -Activity 'Countdown  -'
Do{
	if($quickPoll -eq $true){
		Start-Sleep -Seconds 1
	}
	else{
		if( $endDateTime -lt (Get-Date).AddMinutes(3) ){
			$quickPoll = $true
		}
		Start-Sleep -Seconds 60
	}
	if( $cursor::Position -ne $initialPosition ){
		[System.Windows.Forms.SendKeys]::SendWait("{F14}")
		$action = '+'
	}
	else{
		$action = '-'
	}
	$initialPosition = $cursor::Position
	$timeRemaining = ($endDateTime - ( Get-Date ))
    $complete = ((($timeRemaining).totalMilliseconds) / (($initialDuration).totalMilliseconds))*100
    Write-Progress -PercentComplete $complete -SecondsRemaining $timeRemaining.totalSeconds -Activity ('Countdown {0}' -f $action)
}
While( (Get-Date) -lt $endDateTime )