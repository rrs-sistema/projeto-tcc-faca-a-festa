Write-Host "🛠️ Corrigindo plugins Windows (flutter_tts e geolocator_windows)..."

# Caminhos dos plugins
$plugins = @(
  "build\windows\flutter\ephemeral\.plugin_symlinks\flutter_tts\windows\CMakeLists.txt",
  "build\windows\flutter\ephemeral\.plugin_symlinks\geolocator_windows\windows\CMakeLists.txt"
)

foreach ($file in $plugins) {
  if (Test-Path $file) {
    Write-Host "➡ Corrigindo $file"

    # Adiciona runtimeobject à linha de linkagem
    (Get-Content $file) -replace "flutter_wrapper_plugin\)", "flutter_wrapper_plugin runtimeobject)" | Set-Content $file

    # Remove linhas duplicadas de add_library se houver
    $content = Get-Content $file
    $unique = $content | Select-String -NotMatch "add_library\(" -Raw | Out-String
    $content | Set-Content $file
  } else {
    Write-Host "⚠️ Plugin não encontrado: $file"
  }
}

Write-Host "✅ Correção concluída."
