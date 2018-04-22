Import-Module powershell-yaml
. $PSScriptRoot\..\functions\kubernetes_functions.ps1


Describe 'ConvertFrom-KubernetesServiceDefinition' {
  It "Convert service + deployment definition" {
	[string]$KubernetesComplexDefinition = Get-Content -Raw -Path $PSScriptRoot\..\examples\kubernetes\complexService_and_Deployment.yaml
	$DockerServiceConfig = ConvertFrom-KubernetesServiceDefinition $KubernetesComplexDefinition
	$DockerServiceConfigShouldBe = @"
{
    "name":  "example",
    "labels":  {
                   "app":  "example",
                   "tier":  "frontend"
               },
    "ports":  [
                  {
                      "targetPort":  80,
                      "port":  80
                  },
                  {
                      "port":  8081,
                      "protocol":  "TCP",
                      "targetPort":  81
                  }
              ],
    "mode":  "replicated",
    "replicas":  2,
    "container-labels":  {
                             "app":  "example",
                             "tier":  "frontend"
                         },
    "secrets":  [
                    {
                        "source":  "example-secret1",
                        "target":  "/run/secrets/example-secret1"
                    },
                    {
                        "source":  "example-secret2",
                        "target":  "/run/secrets/example-secret2"
                    }
                ],
    "image":  "nginx"
}
"@
	$DockerServiceConfig | ConvertTo-Json | Should -Be $DockerServiceConfigShouldBe
  }


  It "Convert global mode definition" {
	$KubernetesServiceDefinition = Get-Content -Raw -Path $PSScriptRoot\..\examples\kubernetes\simpleGlobalMode.yaml
	$DockerServiceConfig = ConvertFrom-KubernetesServiceDefinition $KubernetesServiceDefinition
	$DockerServiceConfigShouldBe = @"
{
    "name":  "example",
    "mode":  "global",
    "image":  "nginx:v1"
}
"@
	$DockerServiceConfig | ConvertTo-Json | Should -Be $DockerServiceConfigShouldBe
  }
}



Describe 'ConvertFrom-KubernetesSecretDefinition' {
  It "Convert secret definition" {
	$KubernetesSecretDefinition = @"
apiVersion: v1
kind: Secret
metadata:
  name: example-secret
type: Opaque
data:
  example-secret: cGFzc3dvcmQ=
"@

    $DockerSecret = ConvertFrom-KubernetesSecretDefinition $KubernetesSecretDefinition
	$DockerSecretConfigShouldBe = @"
{
    "name":  "example-secret",
    "data":  "cGFzc3dvcmQ="
}
"@
    $DockerSecret | ConvertTo-Json | Should -Be $DockerSecretConfigShouldBe

  }
}