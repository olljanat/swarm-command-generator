$ErrorActionPreference = "Stop"

if (!(Get-Module -Name Pester -List)) { Install-Module -Name Pester -Force -SkipPublisherCheck }

Write-Information "Prepaire env for testing. This will take a while"
docker service create --name valid-service-name nginx | Out-Null
Write-Output "dummy" | docker config create valid-config-name1 - | Out-Null
Write-Output "dummy" | docker config create valid-config-name2 - | Out-Null
Write-Output "secret" | docker secret create valid-secret-name1 - | Out-Null
Write-Output "secret" | docker secret create valid-secret-name2 - | Out-Null

. $PSScriptRoot\test_kubernetes_functions.ps1
. $PSScriptRoot\test_secret_functions.ps1
. $PSScriptRoot\test_service_functions.ps1

Write-Information "Cleaning up env after testing. This will take a while"
docker service rm valid-service-name | Out-Null
docker config rm valid-config-name1 | Out-Null
docker config rm valid-config-name2 | Out-Null
docker secret rm valid-secret-name1 | Out-Null
docker secret rm valid-secret-name2 | Out-Null