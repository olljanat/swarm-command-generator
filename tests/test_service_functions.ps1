. $PSScriptRoot\..\functions\service_functions.ps1

Describe 'Test-DockerServiceDefinition' {
  It "Given valid -Definition, it returns $true" {
	$validDefinition = @"
		{
			"name": "example2",
			"image":"nginx"
		}
"@
	Test-DockerServiceDefinition $($validDefinition | ConvertFrom-Json) | Should -Be $true
  }
  
  It "Given invalid -Definition, it returns $false" {
	$invalidDefinition = @"
		{
			"name": "example2"
		}
"@
	Test-DockerServiceDefinition $($invalidDefinition | ConvertFrom-Json) | Should -Be $false
  }
}

Describe 'Test-DockerService' {
  It "Invalid service name, it returns $false" {
	$invalidServiceName = @"
		{
			"name": "invalid-service-name"
		}
"@
	Test-DockerService $($invalidServiceName | ConvertFrom-Json) | Should -Be $false
  }
  
  It "Valid service name, it returns $true" {

	$validServiceName = @"
		{
			"name": "valid-service-name"
		}
"@
	Test-DockerService $($validServiceName | ConvertFrom-Json) | Should -Be $true
  }
}

Describe 'New-DockerService' {
	$simpleService = Get-Content $PSScriptRoot\..\examples\service\simpleService.json

  It "Generate service create command on powershell format" {

	$simpleServicePSCommand = New-DockerService $($simpleService | ConvertFrom-Json)
	$simpleServicePSCommandShouldBe = @"
docker service create ``
--mode global ``
--name simple-service nginx
"@
	$simpleServicePSCommand | Should -Be $simpleServicePSCommandShouldBe
  }
  
  It "Generate service create command on bash format" {
	$simpleServiceBashCommand = New-DockerService $($simpleService | ConvertFrom-Json) "bash"
	$simpleServiceBashCommandShouldBe = @"
docker service create \
--mode global \
--name simple-service nginx
"@
	$simpleServiceBashCommand | Should -Be $simpleServiceBashCommandShouldBe
  }

 
	$complexService = Get-Content $PSScriptRoot\..\examples\service\complexService.json
  It "Generates service create command for complex service (bash)" {
	$complexServicePSCommand = New-DockerService $($complexService | ConvertFrom-Json) "bash"
	$complexServicePSCommandShouldBe = @"
docker service create \
--label app=example \
--label tier=frontend \
--publish published=80,target=81 \
--publish published=8081,protocol=TCP,target=81 \
--mode replicated \
--replicas 2 \
--container-label app=example \
--container-label tier=frontend \
--env sqlserver=srv1 \
--env ASPNETCORE_ENVIRONMENT=Development \
--constraint node.role==worker \
--constraint node.platform.os==linux \
--secret source=example-secret1,target=/run/secrets/example-secret1 \
--secret source=example-secret2,target=/run/secrets/example-secret2 \
--name example nginx
"@
	$complexServicePSCommand | Should -Be $complexServicePSCommandShouldBe
  }
}
