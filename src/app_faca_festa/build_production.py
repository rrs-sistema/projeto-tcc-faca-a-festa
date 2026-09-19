#!/usr/bin/env python3
"""
Gera builds de produção do Faça a Festa.

Uso (CMD / PowerShell), na raiz do projeto:

  python build_production.py
  python build_production.py --all
  python build_production.py --windows
  python build_production.py --web
  python build_production.py --web --deploy
  python build_production.py --apk
  python build_production.py --bundle
  python build_production.py --windows --web --deploy
  python build_production.py --windows --web --bundle --deploy
  python build_production.py --windows --web --apk --bundle --deploy

Versão (padrão: incrementa patch + build, ex.: 1.0.0+2 -> 1.0.1+3):
  python build_production.py                  # bump automático
  python build_production.py --no-bump        # mantém versão atual
  python build_production.py --bump-build     # só +build
  python build_production.py --bump minor     # 1.0.0+2 -> 1.1.0+3
  python build_production.py --bump major     # 1.0.0+2 -> 2.0.0+3

Requisitos:
  - Flutter no PATH
  - Inno Setup 6 (ISCC.exe) para o Setup Windows
  - firebase-tools (firebase) no PATH se usar --deploy
  - android/key.properties configurado para assinar APK/AAB
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import time
from datetime import date
from pathlib import Path


ROOT = Path(__file__).resolve().parent
ISS_PATH = ROOT / "installer" / "windows" / "FacaFesta.iss"
PUBSPEC = ROOT / "pubspec.yaml"
SETUP_OUT_DIR = ROOT / "release" / "windows-installer"
SETUP_PREFIX = "FacaFesta_Setup_v"
APK_PATH = ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
AAB_PATH = ROOT / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"
WEB_DIR = ROOT / "build" / "web"
WIN_EXE = (
    ROOT / "build" / "windows" / "x64" / "runner" / "Release" / "app_faca_festa.exe"
)
HOSTING_URL = "https://faca-a-festa.web.app"


def log(msg: str) -> None:
    print(f"\n==> {msg}", flush=True)


def fail(msg: str, code: int = 1) -> None:
    print(f"\n[ERRO] {msg}", file=sys.stderr, flush=True)
    raise SystemExit(code)


def which(cmd: str) -> str | None:
    return shutil.which(cmd)


def run(
    cmd: list[str],
    *,
    cwd: Path | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    printable = subprocess.list2cmdline(cmd)
    print(f"$ {printable}", flush=True)
    started = time.time()
    proc = subprocess.run(
        cmd,
        cwd=str(cwd or ROOT),
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    elapsed = time.time() - started
    if proc.stdout:
        # Windows console (cp1252) quebra com ✓/√ do Flutter; sanitiza saída.
        safe = proc.stdout.encode(sys.stdout.encoding or "utf-8", errors="replace").decode(
            sys.stdout.encoding or "utf-8", errors="replace"
        )
        print(safe, end="" if safe.endswith("\n") else "\n", flush=True)
    if check and proc.returncode != 0:
        fail(f"Comando falhou (exit {proc.returncode}) em {elapsed:.1f}s:\n  {printable}")
    print(f"[OK] {elapsed:.1f}s" if proc.returncode == 0 else f"[FAIL] {elapsed:.1f}s", flush=True)
    return proc


def is_file_lock_error(output: str) -> bool:
    markers = (
        "errno = 1224",
        "seção mapeada pelo usuário",
        "being used by another program",
        "The file is being used by another program",
        "Cannot open file",
    )
    low = output.lower()
    return any(m.lower() in low for m in markers)


def clear_generated_plugin_files() -> None:
    """Tenta liberar arquivos gerados que costumam travar no Windows (AV/IDE)."""
    candidates = [
        ROOT / "linux" / "flutter" / "generated_plugin_registrant.cc",
        ROOT / "linux" / "flutter" / "generated_plugin_registrant.h",
        ROOT / "linux" / "flutter" / "generated_plugins.cmake",
        ROOT / "windows" / "flutter" / "generated_plugin_registrant.cc",
        ROOT / "windows" / "flutter" / "generated_plugin_registrant.h",
        ROOT / "windows" / "flutter" / "generated_plugins.cmake",
        ROOT / "macos" / "Flutter" / "GeneratedPluginRegistrant.swift",
        ROOT / "macos" / "Flutter" / "ephemeral" / "Flutter-Generated.xcconfig",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        try:
            path.unlink()
            print(f"  removido: {path}", flush=True)
        except OSError as exc:
            bak = path.with_suffix(path.suffix + f".locked_{int(time.time())}")
            try:
                path.rename(bak)
                print(f"  renomeado (locked): {path} -> {bak.name}", flush=True)
            except OSError:
                print(f"  ainda bloqueado: {path} ({exc})", flush=True)


def run_flutter_build_with_retries(
    cmd: list[str],
    *,
    label: str,
    attempts: int = 4,
    wait_seconds: float = 8.0,
) -> None:
    last_output = ""
    for attempt in range(1, attempts + 1):
        log(f"{label} (tentativa {attempt}/{attempts})")
        proc = run(cmd, check=False)
        if proc.returncode == 0:
            return
        last_output = proc.stdout or ""
        if not is_file_lock_error(last_output):
            fail(
                f"Comando falhou (exit {proc.returncode}):\n  "
                f"{subprocess.list2cmdline(cmd)}"
            )
        print(
            "\n[AVISO] Arquivo bloqueado (errno 1224). "
            "Limpando gerados e aguardando antes de tentar de novo...",
            flush=True,
        )
        clear_generated_plugin_files()
        if attempt < attempts:
            time.sleep(wait_seconds * attempt)

    fail(
        "Build falhou por arquivo bloqueado após várias tentativas.\n"
        "Feche o app em execução, pause o antivírus nesta pasta e "
        "feche outros terminais Flutter; depois rode de novo.\n"
        f"Última saída:\n{last_output[-2000:]}"
    )


def read_version() -> tuple[str, str]:
    text = PUBSPEC.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([^\s#]+)", text, flags=re.MULTILINE)
    if not match:
        fail("Não encontrei 'version:' em pubspec.yaml")
    full = match.group(1).strip()
    if "+" in full:
        name, build = full.split("+", 1)
    else:
        name, build = full, "0"
    return name, build


def write_version(version_name: str, version_build: str) -> None:
    text = PUBSPEC.read_text(encoding="utf-8")
    new_full = f"{version_name}+{version_build}"
    updated, n = re.subn(
        r"^version:\s*[^\s#]+",
        f"version: {new_full}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if n != 1:
        fail("Não consegui gravar a nova versão em pubspec.yaml")
    PUBSPEC.write_text(updated, encoding="utf-8")
    log(f"pubspec.yaml atualizado: version: {new_full}")


def parse_semver(version_name: str) -> tuple[int, int, int]:
    parts = version_name.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        fail(f"Versão inválida (esperado X.Y.Z): {version_name}")
    return int(parts[0]), int(parts[1]), int(parts[2])


def bump_version(
    version_name: str,
    version_build: str,
    *,
    kind: str,
) -> tuple[str, str]:
    major, minor, patch = parse_semver(version_name)
    try:
        build = int(version_build)
    except ValueError:
        fail(f"Build number inválido: {version_build}")

    if kind == "patch":
        patch += 1
    elif kind == "minor":
        minor += 1
        patch = 0
    elif kind == "major":
        major += 1
        minor = 0
        patch = 0
    elif kind == "build":
        pass
    else:
        fail(f"Tipo de bump inválido: {kind}")

    build += 1
    return f"{major}.{minor}.{patch}", str(build)


def find_iscc() -> Path:
    env = os.environ.get("ISCC_PATH")
    if env:
        p = Path(env)
        if p.is_file():
            return p

    for name in ("iscc", "ISCC", "ISCC.exe"):
        found = which(name)
        if found:
            return Path(found)

    candidates = [
        Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
        / "Inno Setup 6"
        / "ISCC.exe",
        Path(os.environ.get("ProgramFiles", r"C:\Program Files"))
        / "Inno Setup 6"
        / "ISCC.exe",
        Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)"))
        / "Inno Setup 5"
        / "ISCC.exe",
    ]
    for p in candidates:
        if p.is_file():
            return p

    fail(
        "ISCC.exe (Inno Setup) não encontrado.\n"
        "Instale o Inno Setup 6 ou defina ISCC_PATH com o caminho completo do ISCC.exe."
    )


def sync_iss(version_name: str, version_build: str) -> None:
    if not ISS_PATH.is_file():
        fail(f"Arquivo ISS não encontrado: {ISS_PATH}")

    text = ISS_PATH.read_text(encoding="utf-8")
    project_dir = str(ROOT).replace("/", "\\")
    file_version = f"{version_name}.{version_build}"
    version_label = f"{version_name}+{version_build}"

    replacements = [
        (
            r'(#define\s+MyAppVersion\s+")[^"]*(")',
            lambda m: f"{m.group(1)}{version_name}{m.group(2)}",
        ),
        (
            r'(#define\s+MyAppFileVersion\s+")[^"]*(")',
            lambda m: f"{m.group(1)}{file_version}{m.group(2)}",
        ),
        (
            r'(#define\s+ProjectDir\s+")[^"]*(")',
            lambda m: f"{m.group(1)}{project_dir}{m.group(2)}",
        ),
        (
            r"(; Alinhado ao pubspec\.yaml: version: )[^\r\n]*",
            lambda m: f"{m.group(1)}{version_label}",
        ),
    ]

    new_text = text
    for pattern, repl in replacements:
        updated, n = re.subn(pattern, repl, new_text, count=1)
        if n == 0:
            fail(f"Não consegui atualizar o ISS com o padrão: {pattern}")
        new_text = updated

    if new_text != text:
        ISS_PATH.write_text(new_text, encoding="utf-8")
        log(f"ISS atualizado: versão {version_label}, ProjectDir={project_dir}")
    else:
        log("ISS já estava alinhado com pubspec/caminho do projeto")


def ensure_flutter() -> str:
    flutter = which("flutter")
    if not flutter:
        fail("Flutter não encontrado no PATH.")
    return flutter


def ensure_firebase() -> str:
    firebase = which("firebase")
    if not firebase:
        fail("firebase-tools não encontrado no PATH (necessário para --deploy).")
    return firebase


def step_pub_get(flutter: str) -> None:
    log("flutter pub get")
    run([flutter, "pub", "get"])


def step_windows(flutter: str, version_name: str, version_build: str) -> Path:
    sync_iss(version_name, version_build)
    clear_generated_plugin_files()
    run_flutter_build_with_retries(
        [flutter, "build", "windows", "--release"],
        label="Build Windows (--release)",
    )

    if not WIN_EXE.is_file():
        fail(f"Executável Windows não gerado: {WIN_EXE}")

    iscc = find_iscc()
    log(f"Compilando instalador com {iscc}")
    run([str(iscc), str(ISS_PATH)])

    today = date.today().isoformat()
    expected = SETUP_OUT_DIR / today / f"{SETUP_PREFIX}{version_name}.exe"
    if expected.is_file():
        return expected

    matches = sorted(
        SETUP_OUT_DIR.glob(f"**/{SETUP_PREFIX}{version_name}.exe"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    if not matches:
        fail("Setup gerado não encontrado em release/windows-installer/")
    return matches[0]


def step_web(flutter: str, deploy: bool) -> None:
    log("Build Web (--release, --no-tree-shake-icons)")
    if WEB_DIR.exists():
        shutil.rmtree(WEB_DIR, ignore_errors=True)
    run_flutter_build_with_retries(
        [flutter, "build", "web", "--release", "--no-tree-shake-icons"],
        label="Build Web (--release)",
    )

    if not (WEB_DIR / "index.html").is_file():
        fail(f"Build web incompleto: {WEB_DIR}")

    if deploy:
        firebase = ensure_firebase()
        log("Deploy Firebase Hosting")
        run([firebase, "deploy", "--only", "hosting"])


def step_apk(flutter: str) -> Path:
    run_flutter_build_with_retries(
        [flutter, "build", "apk", "--release"],
        label="Build APK Android (--release)",
        attempts=3,
        wait_seconds=10.0,
    )
    if not APK_PATH.is_file():
        fail(f"APK não encontrado: {APK_PATH}")
    return APK_PATH


def step_bundle(flutter: str, version_name: str, version_build: str) -> Path:
    run_flutter_build_with_retries(
        [flutter, "build", "appbundle", "--release"],
        label="Build App Bundle Android (--release)",
        attempts=3,
        wait_seconds=10.0,
    )
    if not AAB_PATH.is_file():
        fail(f"AAB não encontrado: {AAB_PATH}")

    out_dir = ROOT / "release" / "play-store"
    out_dir.mkdir(parents=True, exist_ok=True)
    dest = out_dir / f"FacaFesta_{version_name}+{version_build}.aab"
    shutil.copy2(AAB_PATH, dest)
    log(f"AAB copiado para {dest}")
    return dest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gera builds de produção (Windows Setup, Web, APK e AAB)."
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Gera Windows + Web + APK (padrão se nenhum alvo for informado).",
    )
    parser.add_argument("--windows", action="store_true", help="Gera Setup Windows.")
    parser.add_argument("--web", action="store_true", help="Gera build Web.")
    parser.add_argument("--apk", action="store_true", help="Gera APK Android.")
    parser.add_argument(
        "--bundle",
        action="store_true",
        help="Gera App Bundle (.aab) para a Play Store.",
    )
    parser.add_argument(
        "--deploy",
        action="store_true",
        help="Após o build web, faz firebase deploy --only hosting.",
    )
    parser.add_argument(
        "--skip-pub-get",
        action="store_true",
        help="Não executa flutter pub get.",
    )
    bump = parser.add_mutually_exclusive_group()
    bump.add_argument(
        "--no-bump",
        action="store_true",
        help="Não incrementa a versão (usa a atual do pubspec.yaml).",
    )
    bump.add_argument(
        "--bump-build",
        action="store_true",
        help="Incrementa só o +build (ex.: 1.0.0+2 -> 1.0.0+3).",
    )
    bump.add_argument(
        "--bump",
        choices=("patch", "minor", "major", "build"),
        default=None,
        help="Tipo de incremento. Padrão sem flag: patch (1.0.0+2 -> 1.0.1+3).",
    )
    return parser.parse_args()


def resolve_bump_kind(args: argparse.Namespace) -> str | None:
    if args.no_bump:
        return None
    if args.bump_build:
        return "build"
    if args.bump:
        return args.bump
    return "patch"


def main() -> None:
    if os.name != "nt":
        fail("Este script é destinado ao Windows (CMD/PowerShell).")

    args = parse_args()
    targets = {
        "windows": args.windows,
        "web": args.web,
        "apk": args.apk,
        "bundle": args.bundle,
    }
    if args.all or not any(targets.values()):
        targets = {
            "windows": True,
            "web": True,
            "apk": True,
            "bundle": False,
        }

    if args.deploy and not targets["web"]:
        fail("--deploy exige --web (ou --all / padrão).")

    old_name, old_build = read_version()
    bump_kind = resolve_bump_kind(args)
    if bump_kind is None:
        version_name, version_build = old_name, old_build
        log(f"Versão (sem bump): {version_name}+{version_build}")
    else:
        version_name, version_build = bump_version(
            old_name, old_build, kind=bump_kind
        )
        log(
            f"Versão: {old_name}+{old_build} -> {version_name}+{version_build} "
            f"(bump={bump_kind})"
        )
        write_version(version_name, version_build)
        sync_iss(version_name, version_build)

    log(f"Projeto: {ROOT}")

    flutter = ensure_flutter()
    if not args.skip_pub_get:
        step_pub_get(flutter)

    results: list[str] = [f"Versão: {version_name}+{version_build}"]

    if targets["windows"]:
        setup = step_windows(flutter, version_name, version_build)
        results.append(f"Setup Windows: {setup}")

    if targets["web"]:
        step_web(flutter, deploy=args.deploy)
        results.append(f"Web: {WEB_DIR}")
        if args.deploy:
            results.append(f"Hosting: {HOSTING_URL}")

    if targets["apk"]:
        apk = step_apk(flutter)
        size_mb = apk.stat().st_size / (1024 * 1024)
        results.append(f"APK: {apk} ({size_mb:.1f} MB)")

    if targets["bundle"]:
        aab = step_bundle(flutter, version_name, version_build)
        size_mb = aab.stat().st_size / (1024 * 1024)
        results.append(f"AAB (Play Store): {aab} ({size_mb:.1f} MB)")

    print("\n" + "=" * 60)
    print("PRODUÇÃO CONCLUÍDA")
    print("=" * 60)
    for line in results:
        print(f" - {line}")
    print()


if __name__ == "__main__":
    main()
