[Setup]
AppName=Estok
AppVersion=1.0
DefaultDirName={autopf}\Estok
DefaultGroupName=Estok
OutputBaseFilename=EstokSetup
Compression=lzma
SolidCompression=yes
OutputDir=Installer
; Ensure the installer runs as 64-bit if the app is 64-bit (Flutter Windows is 64-bit usually)
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Server
Source: "estok-py\dist\estok-server.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "estok-py\logo_green.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "estok-py\logo_green_tray.png"; DestDir: "{app}"; Flags: ignoreversion
Source: "estok-db\schema.sql"; DestDir: "{app}\estok-db"; Flags: ignoreversion
Source: "estok-py\db_config.json"; DestDir: "{app}"; Flags: ignoreversion

; Client (Flutter)
; We assume the build is in this path. Adjust if needed.
Source: "estok-fe\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Estok Server"; Filename: "{app}\estok-server.exe"; IconFilename: "{app}\logo_green.ico"
Name: "{group}\Estok Client"; Filename: "{app}\stock_fe.exe"
Name: "{autodesktop}\Estok Server"; Filename: "{app}\estok-server.exe"; IconFilename: "{app}\logo_green.ico"; Tasks: desktopicon
Name: "{autodesktop}\Estok Client"; Filename: "{app}\stock_fe.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\estok-server.exe"; Description: "{cm:LaunchProgram,Estok Server}"; Flags: nowait postinstall skipifsilent
