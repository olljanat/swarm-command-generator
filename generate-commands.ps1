$ErrorActionPreference = "Stop"

. $PSScriptRoot\functions\service_functions.ps1

$serviceDefinitionFiles = Get-ChildItem -Path $PSScriptRoot\examples\service -Filter *.json
ForEach ($File in $serviceDefinitionFiles) {
    $Definition = Get-Content -Path $File.FullName | ConvertFrom-Json
    if (Test-DockerServiceDefinition $Definition)
    {
        if (Test-DockerService $Definition)
        {
            $ServiceInfo = Get-DockerServiceInfo $Definition
            if (!($Definition.mode)) { $Definition | Add-Member -NotePropertyName mode -NotePropertyValue replicated } # Use mode=replicated if not defined
            if ($ServiceInfo.Spec.Mode.PSObject.Properties.Name.ToLower() -eq $Definition.mode)
            {
                Write-Information "Service `"$($Definition.name)`" exists, will update..."
                [array]$commands += Update-DockerService $Definition
            }
            else
            {
                Write-Warning "Service `"$($Definition.name)`" exists, but need to be re-created"
                [array]$commands += "docker service rm $($Definition.name)"
                [array]$commands += New-DockerService $Definition "powershell"
            }
        }
        else
        {
            Write-Information "Service `"$($Definition.name)`" is missing, will create..."
            [array]$commands += New-DockerService $Definition "powershell"
        }
        Remove-Variable -Name Definition -ErrorAction:SilentlyContinue
        Remove-Variable -Name ServiceInfo -ErrorAction:SilentlyContinue
    }
    else
    {
        Write-Warning "Service definition file `"$($File.Name)`" is invalid. Will skip..."
        Remove-Variable -Name Definition -ErrorAction:SilentlyContinue
        continue
    }
}

Remove-Variable -Name serviceDefinitionFiles -ErrorAction:SilentlyContinue
Remove-Variable -Name File -ErrorAction:SilentlyContinue
return $commands