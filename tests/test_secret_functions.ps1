. $PSScriptRoot\..\functions\secret_functions.ps1


Describe 'Test-DockerSecret' {
  It "Invalid secret name, it returns $false" {
	$invalidSecretName = @"
		{
			"name": "invalid-secret-name"
		}
"@
	Test-DockerSecret $($invalidSecretName | ConvertFrom-Json) | Should -Be $false
  }
  
  It "Valid Secret name, it returns $true" {

	$validSecretName = @"
		{
			"name": "valid-secret-name1"
		}
"@
	Test-DockerSecret $($validSecretName | ConvertFrom-Json) | Should -Be $true
  }
}

Describe 'New-DockerSecret' {
	$simpleSecret = Get-Content $PSScriptRoot\..\examples\secret\simpleSecret.json

  It "Generate Secret create command on bash format" {

	$simpleSecretBashCommand = New-DockerSecret $($simpleSecret | ConvertFrom-Json) "bash"
	$simpleSecretBashCommandShouldBe = @"
echo "cGFzc3dvcmQ=" | base64 --decode | docker secret create example-secret -
"@
	$simpleSecretBashCommand | Should -Be $simpleSecretBashCommandShouldBe
  }

  It "Generate Secret create command on powershell format" {

	$simpleSecretPSCommand = New-DockerSecret $($simpleSecret | ConvertFrom-Json)
	$simpleSecretPSCommandShouldBe = @"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("cGFzc3dvcmQ=")) | docker secret create example-secret -
"@
	$simpleSecretPSCommand | Should -Be $simpleSecretPSCommandShouldBe
  }
}
