# Cria a chave de upload do Faça a Festa (não versionar o .jks nem o key.properties).
# Uso: powershell -ExecutionPolicy Bypass -File android\create-upload-keystore.ps1

$ErrorActionPreference = "Stop"
$jks = Join-Path $env:USERPROFILE "facafesta-upload-keystore.jks"
$props = Join-Path $PSScriptRoot "key.properties"

$keytool = $null
$cmd = Get-Command keytool -ErrorAction SilentlyContinue
if ($cmd) { $keytool = $cmd.Source }
if (-not $keytool -and $env:JAVA_HOME) {
  $candidate = Join-Path $env:JAVA_HOME "bin\keytool.exe"
  if (Test-Path $candidate) { $keytool = $candidate }
}
if (-not $keytool) {
  throw "keytool não encontrado. Instale um JDK ou abra o terminal onde o Flutter/Android Studio já funciona."
}

if (Test-Path $jks) {
  Write-Host "O arquivo já existe: $jks"
  Write-Host "Nada foi sobrescrito. Ajuste android/key.properties se a senha já estiver lá."
  exit 0
}

$pass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

& $keytool -genkeypair `
  -keystore $jks `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias facafesta `
  -dname "CN=Faca a Festa, OU=RRS System Technology, O=RRS System Technology, L=Curitiba, ST=Parana, C=BR" `
  -storepass $pass `
  -keypass $pass

$jksPosix = ($jks -replace '\\', '/')
@"
storePassword=$pass
keyPassword=$pass
keyAlias=facafesta
storeFile=$jksPosix
"@ | Set-Content -Path $props -Encoding ASCII

Write-Host ""
Write-Host "Keystore criado em: $jks"
Write-Host "Senhas gravadas em: $props (arquivo ignorado pelo Git)."
Write-Host "Faça backup desses dois arquivos. Sem eles não dá para atualizar o app na Play."
Write-Host ""
& $keytool -list -v -keystore $jks -alias facafesta -storepass $pass |
  Select-String -Pattern "SHA1:","SHA256:"
