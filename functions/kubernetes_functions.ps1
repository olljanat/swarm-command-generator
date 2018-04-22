Function ConvertFrom-KubernetesServiceDefinition {
    <#
    .SYNOPSIS
    Converts Kubernetes service+deployment definition to docker swarm format
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$KubernetesServiceDefinition
    )
    $DefinitionSplit = $KubernetesServiceDefinition -split "---"
	$ServiceConfig = New-Object -TypeName PSObject
	ForEach ($Section in $DefinitionSplit) {
		$temp = $Section | ConvertFrom-Yaml
        switch ($temp.kind)
        {
			"Service" {
				$ServiceConfig | Add-Member -MemberType NoteProperty -Name "name" -Value $temp.metadata.name
				
				If ($temp.metadata.labels)
				{
					$ServiceLabels = New-Object -TypeName PSObject
					ForEach ($Label in $temp.metadata.labels.GetEnumerator()) {
						$ServiceLabels | Add-Member -MemberType NoteProperty -Name $Label.Name -Value $Label.Value
					}
					$ServiceConfig | Add-Member -MemberType NoteProperty -Name "labels" -Value $ServiceLabels
				}
                If ($temp.spec.ports)
                {
                    ForEach ($PortSpec in $temp.spec.ports) {
                        $portProperties = New-Object -TypeName PSObject
                        ForEach ($Port in $PortSpec.GetEnumerator())
                        {
                            $portProperties | Add-Member -MemberType NoteProperty -Name $Port.Name -Value $Port.Value
                        }
                        [array]$portsList += $portProperties
                        Remove-Variable -Name portProperties
                    }
                    $ServiceConfig | Add-Member -MemberType NoteProperty -Name "ports" -Value $portsList
                }
			}

            "Deployment" {
                If ($temp.spec.replicas)
                {
                    $ServiceConfig | Add-Member -MemberType NoteProperty -Name "mode" -Value "replicated"
                    $ServiceConfig | Add-Member -MemberType NoteProperty -Name "replicas" -Value $temp.spec.replicas
                }
                Else
                {
                    $ServiceConfig | Add-Member -MemberType NoteProperty -Name "mode" -Value "global"
                }

				If ($temp.spec.template.metadata.labels)
				{
					$ContainerLabels = New-Object -TypeName PSObject
					ForEach ($Label in $temp.spec.template.metadata.labels.GetEnumerator()) {
						$ContainerLabels | Add-Member -MemberType NoteProperty -Name $Label.Name -Value $Label.Value
					}
					$ServiceConfig | Add-Member -MemberType NoteProperty -Name "container-labels" -Value $ContainerLabels
				}

                If ($temp.spec.template.spec.volumes)
                {
                    ForEach ($volume in $temp.spec.template.spec.volumes)
                    {
                        If ($volume.secret.secretName)
                        {
                            $secretProperties = New-Object -TypeName PSObject
                            $volumeMount = $temp.spec.template.spec.containers.volumeMounts | Where-Object {$_.name -eq $volume.secret.secretName}
                            if ($volumeMount.count -ne 1)
                            {
                                $secretProperties | Add-Member -MemberType NoteProperty -Name "source" -Value $volume.secret.secretName
                                $secretProperties | Add-Member -MemberType NoteProperty -Name "target" -Value $($volumeMount.mountPath + "/" + $volumeMount.name)
                            }
                            else
                            {
                                throw "Cannot find mount settings for $($volume.secret.secretName)"
                            }
                            [array]$secretsList += $secretProperties
                            Remove-Variable -Name secretProperties
                        }
                        else
                        {
                            Write-Warning "Currently only secret volumes are supported, will skip..."
                        }
                    }
                    $ServiceConfig | Add-Member -MemberType NoteProperty -Name "secrets" -Value $secretsList
                }


                If ($temp.spec.template.spec.containers.image) {
                    $ServiceConfig | Add-Member -MemberType NoteProperty -Name "image" -Value $temp.spec.template.spec.containers.image
                }
            }

			default {
				throw "Kind `"$($temp.kind)`" is not supported"
			}
		}
	}
	
	return $ServiceConfig
}


Function ConvertFrom-KubernetesSecretDefinition {
    <#
    .SYNOPSIS
    Converts Kubernetes secret definition to docker swarm format
    #>
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]$KubernetesSecretDefinition
    )

    $Definition = $KubernetesSecretDefinition | ConvertFrom-Yaml
    $Secret = New-Object -TypeName PSObject

    If ($Definition.kind -eq "Secret")
    {
        $Secret | Add-Member -MemberType NoteProperty -Name "name" -Value $Definition.metadata.name
        If ($Definition.data.$($Definition.metadata.name))
        {
            $Secret | Add-Member -MemberType NoteProperty -Name "data" -Value $Definition.data.$($Definition.metadata.name)
        }
        else
        {
            throw "Cannot find data field with name $($Definition.metadata.name) which is only swarm compatible value"
        }
    }
    else
    {
        throw "Kind `"$($Definition.kind)`" is not supported by this function"
    }

    return $Secret

}