Function Test-DockerServiceDefinition {
    <#
    .SYNOPSIS
    Verify that docker service definition contains mandatory parameters.
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Definition
    )
    if (($Definition.name) -and ($Definition.image))
    {
        return $true
    }
    else
    {
        return $false
    }
}

Function Test-DockerService {
    <#
    .SYNOPSIS
    Check if docker service already exists.
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Definition
    )

    [array]$DockerServices = docker service ls --format "{{.Name}}"
    if ($DockerServices | Where-Object {$_ -eq "$($Definition.name)"})
    {
        return $true
    }
    else
    {
        return $false
    }
}

Function New-DockerService {
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
		$NewLineDelimiter = "\"
	}
	else
	{
		$NewLineDelimiter = "``"
	}

    [string]$command = "docker service create $NewLineDelimiter`r`n"
    ForEach ($Property in $Definition.PSObject.Properties)
    {
        switch ($Property.Name)
        {
            "name"{ $name = $Property.Value }
            "image" { $image = $Property.Value }
			"configs" {
				ForEach ($config in $Definition.configs.name)
				{
					$command += "--config $config $NewLineDelimiter`r`n"
				}
			}
			"secrets" {
				ForEach ($secret in $Definition.secrets)
				{
                    if (($secret.source) -and ($secret.target))
                    {
					    $command += "--secret source=$($secret.source),target=$($secret.target) $NewLineDelimiter`r`n"
                    }
                    else
                    {
                        throw "Current implementation requires to specify both source and target fields for secrets"
                    }
				}
			}
            "labels" {
                ForEach ($label in $Definition.labels.PSObject.Properties)
                {
                    $command += "--label $($label.Name)=$($label.Value) $NewLineDelimiter`r`n"
                }
            }
            "container-labels" {
                ForEach ($ContainerLabel in $Definition."container-labels".PSObject.Properties)
                {
                    $command += "--container-label $($ContainerLabel.Name)=$($ContainerLabel.Value) $NewLineDelimiter`r`n"
                }
            }
            "ports" {
                ForEach ($PortSpec in $Definition.ports) {
                    $portCommand = "--publish "
                    ForEach ($Port in $PortSpec.PSObject.Properties)
                    {
                        switch ($Port.Name)
                        {
                            "port" { $portCommand += "published=$($Port.Value)" }
                            "targetPort" { $portCommand += ",target=$($Port.Value)" }
                            "protocol" { $portCommand += ",protocol=$($Port.Value)" }
                            default {
                                throw "Port attribute `"$($Port.Name)`" is not supported"
                            }
                        }
                    }
                    $command += "$portCommand $NewLineDelimiter`r`n"
                    Remove-Variable -Name portCommand
                }
            }
            "env" {
                ForEach ($env in $Definition.env.PSObject.Properties)
                {
                    $command += "--env $($env.Name)=$($env.Value) $NewLineDelimiter`r`n"
                }
            }
            "constraints" {
                ForEach ($constraint in $Definition.constraints) {
                    $command += "--constraint $constraint $NewLineDelimiter`r`n"
                }
            }
            default {
                $command += "--$($Property.Name) $($Property.Value) $NewLineDelimiter`r`n"
            }
        }
    }
    $command += "--name $name $image"
    return $command
}

Function Get-DockerServiceInfo {
    <#
    .SYNOPSIS
    Get docker service detailed information 
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Definition
    )

    $service = docker service inspect $($Definition.name) | ConvertFrom-Json
    return $service
}

Function Update-DockerService {
    <#
    .SYNOPSIS
    Update docker service based on definition file.
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$Definition
    )

    [string]$command = "docker service update"
    ForEach ($Property in $Definition.PSObject.Properties)
    {
        switch ($Property.Name)
        {
            "name" { $name = $Property.Value }
            "image" { $image = $Property.Value.ToLower() }
            "mode" { }
            default {
                $command += " --$($Property.Name) $($Property.Value)"
            }
        }
    }
    $command += " --image $image $name"
    return $command
}