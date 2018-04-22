
Function Test-DockerSecret {
    <#
    .SYNOPSIS
    Check if docker secret already exists.
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Definition
    )

    [array]$DockerSecrets = docker secret ls --format "{{.Name}}"
    if ($DockerSecrets | Where-Object {$_ -eq "$($Definition.name)"})
    {
        return $true
    }
    else
    {
        return $false
    }
}

Function New-DockerSecret {
    <#
    .SYNOPSIS
    Create new docker service based on definition file.
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Definition,
		[Parameter(Mandatory=$false)][ValidateSet("powershell","bash")][string]$format = "powershell"
    )

	if ($format -eq "bash")
	{
		[string]$command = 'echo "'  + $Definition.data + '" | base64 --decode | '
	}
	else
	{
		[string]$command = '[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("' + $Definition.data + '")) | '
	}

    [string]$command = 
    $command += "docker secret create $($Definition.name) -"

    return $command
}