; ======================================================================
; Faça a Festa - Instalador Windows (Inno Setup 6)
; RRS System Technology
;
; Projeto:
;   D:\repository\unicesumar\tcc\app\src\app_faca_festa
;
; Antes de compilar este script:
;   flutter pub get
;   flutter build windows --release
;
; Compilar o instalador (Inno Setup Compiler):
;   iscc installer\windows\FacaFesta.iss
;
; Ou use:
;   python build_production.py --windows
;
; Saída:
;   release\windows-installer\<data>\FacaFesta_Setup_v1.0.0.exe
; ======================================================================

#define MyAppName "Faça a Festa"
; Alinhado ao pubspec.yaml: version: 1.0.1+3
#define MyAppVersion "1.0.1"
#define MyAppFileVersion "1.0.1.3"
#define MyAppPublisher "RRS System Technology"
#define MyAppURL "https://faca-a-festa.web.app/"
#define MyAppExeName "app_faca_festa.exe"
#define MyAppMutex "FacaFesta_App_Mutex"

#define ProjectDir "D:\repository\unicesumar\tcc\app\src\app_faca_festa"
#define BuildDir ProjectDir + "\build\windows\x64\runner\Release"
#define DistDir ProjectDir + "\dist"
#define DistPackDir DistDir + "\FacaFesta_Windows"
#define VCRedistPath DistDir + "\VC_redist.x64.exe"
#define AppIcon ProjectDir + "\windows\runner\resources\app_icon.ico"

#define BuildDate GetDateTimeString('yyyy-mm-dd', '-', ':')

#if FileExists(BuildDir + "\" + MyAppExeName)
  #define AppSourceDir BuildDir
#elif FileExists(DistPackDir + "\" + MyAppExeName)
  #define AppSourceDir DistPackDir
#else
  #error "Executavel nao encontrado. Rode flutter build windows --release."
#endif

[Setup]
AppId={{8F4A2C91-6B17-4E3D-9A50-2C8E7D4F1B63}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
AppCopyright=Copyright (C) {#MyAppPublisher}
AppMutex={#MyAppMutex}

VersionInfoVersion={#MyAppFileVersion}
VersionInfoProductVersion={#MyAppVersion}
VersionInfoProductName={#MyAppName}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=Instalador do {#MyAppName}
VersionInfoCopyright=Copyright (C) {#MyAppPublisher}

DefaultDirName={autopf}\Faca a Festa
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableWelcomePage=no
AllowNoIcons=yes

OutputDir={#ProjectDir}\release\windows-installer\{#BuildDate}
OutputBaseFilename=FacaFesta_Setup_v{#MyAppVersion}

Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
WizardSizePercent=120

MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

SetupLogging=yes
CloseApplications=yes
RestartApplications=no
UsePreviousAppDir=yes
UsePreviousGroup=yes
UsePreviousTasks=yes

UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

#if FileExists(AppIcon)
SetupIconFile={#AppIcon}
#endif

#if !FileExists(AppSourceDir + "\" + MyAppExeName)
  #error "Executavel nao encontrado. Rode: flutter build windows --release"
#endif

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Messages]
ptbr.WelcomeLabel2=Este assistente instalará o [name/ver] no computador.%n%nPlaneje eventos, convites e fornecedores.%n%nÉ recomendável fechar os demais aplicativos antes de continuar.
ptbr.FinishedLabel=A instalação do [name] foi concluída.

[Tasks]
Name: "desktopicon"; \
    Description: "Criar atalho na Área de Trabalho"; \
    GroupDescription: "Atalhos:"; \
    Flags: unchecked

[Files]
Source: "{#AppSourceDir}\*"; \
    DestDir: "{app}"; \
    Excludes: "*.lib,*.exp,*.pdb,*.ilk"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

#if FileExists(VCRedistPath)
Source: "{#VCRedistPath}"; \
    DestDir: "{tmp}"; \
    DestName: "vc_redist.x64.exe"; \
    Flags: deleteafterinstall; \
    Check: ShouldInstallVCRedist
#endif

[Icons]
Name: "{autoprograms}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"; \
    Comment: "Abrir o Faça a Festa"

Name: "{autodesktop}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"; \
    Tasks: desktopicon; \
    Comment: "Abrir o Faça a Festa"

Name: "{autoprograms}\Desinstalar {#MyAppName}"; \
    Filename: "{uninstallexe}"

[Run]
#if FileExists(VCRedistPath)
Filename: "{tmp}\vc_redist.x64.exe"; \
    Parameters: "/install /quiet /norestart"; \
    StatusMsg: "Instalando componentes Microsoft Visual C++..."; \
    Flags: runhidden waituntilterminated; \
    Check: ShouldInstallVCRedist
#endif

Filename: "{app}\{#MyAppExeName}"; \
    WorkingDir: "{app}"; \
    Description: "Iniciar o {#MyAppName} agora"; \
    Flags: nowait postinstall skipifsilent unchecked

[UninstallDelete]
Type: filesandordirs; Name: "{app}\*.log"
Type: files; Name: "{app}\*.tmp"

[Code]

function IsVCRedistInstalled(): Boolean;
var
  Installed: Cardinal;
  Major: Cardinal;
  Key: String;
begin
  Key := 'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64';

  if RegQueryDWordValue(HKLM, Key, 'Installed', Installed) then
  begin
    if Installed = 1 then
    begin
      if RegQueryDWordValue(HKLM, Key, 'Major', Major) then
        Result := (Major >= 14)
      else
        Result := True;
      Exit;
    end;
  end;

  Result := False;
end;

function ShouldInstallVCRedist(): Boolean;
begin
  Result := not IsVCRedistInstalled();
end;
