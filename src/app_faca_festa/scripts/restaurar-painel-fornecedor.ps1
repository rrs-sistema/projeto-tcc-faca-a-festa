[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'
$raizProjeto = Split-Path -Parent $PSScriptRoot
$checkpoint = 'checkpoint/painel-fornecedor-2026-11-19'
$arquivos = @(
    'lib/presentation/modules/fornecedor/pages/fornecedor_home_screen.dart'
    'lib/presentation/modules/fornecedor/sections/solicitacoes_section.dart'
    'lib/presentation/modules/fornecedor/sections/visao_operacional_fornecedor.dart'
    'lib/presentation/modules/fornecedor/sections/resumo_section.dart'
    'lib/presentation/modules/fornecedor/sections/header_section.dart'
    'lib/presentation/modules/fornecedor/sections/demanda_latente_section.dart'
    'lib/presentation/modules/fornecedor/sections/perfil_section.dart'
    'lib/presentation/modules/fornecedor/sections/avaliacoes_section.dart'
    'lib/presentation/modules/fornecedor/sections/atualizacao_indicadores.dart'
    'lib/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart'
    'lib/presentation/modules/avaliacao/widgets/gestao_reputacao_painel.dart'
    'test/features/painel/visao_restaurada_test.dart'
)
$arquivoNovo = 'lib/presentation/modules/fornecedor/sections/pedido_resumo_card.dart'

Push-Location -LiteralPath $raizProjeto
try {
    & git rev-parse --verify "$checkpoint^{commit}" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Checkpoint nao encontrado: $checkpoint" }

    if ($PSCmdlet.ShouldProcess($raizProjeto, "Salvar copia e restaurar somente os arquivos do painel a partir de $checkpoint")) {
        $backup = Join-Path $raizProjeto ('output/painel-backups/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
        foreach ($arquivo in ($arquivos + $arquivoNovo)) {
            $origem = Join-Path $raizProjeto $arquivo
            if (Test-Path -LiteralPath $origem) {
                $destino = Join-Path $backup $arquivo
                New-Item -ItemType Directory -Path (Split-Path -Parent $destino) -Force | Out-Null
                Copy-Item -LiteralPath $origem -Destination $destino
            }
        }

        & git restore "--source=$checkpoint" --worktree -- @arquivos
        if ($LASTEXITCODE -ne 0) { throw "A restauracao falhou. Copia salva em $backup" }

        $caminhoNovo = Join-Path $raizProjeto $arquivoNovo
        if (Test-Path -LiteralPath $caminhoNovo) {
            Remove-Item -LiteralPath $caminhoNovo
        }
        Write-Output "Painel restaurado. Copia da versao substituida: $backup"
    }
}
finally {
    Pop-Location
}
