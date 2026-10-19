#ifndef AppVersion
  #error AppVersion is required
#endif
#ifndef FileVersion
  #error FileVersion is required
#endif
#ifndef SourceDir
  #error SourceDir is required
#endif
#ifndef OutputDir
  #error OutputDir is required
#endif

[Setup]
AppId=io.github.prankerborislavchik.abacus
AppName=Abacus
AppVersion={#AppVersion}
VersionInfoVersion={#FileVersion}
AppPublisher=Abacus contributors
AppPublisherURL=https://github.com/prankerborislavchik/abacus
DefaultDirName={localappdata}\Programs\Abacus
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=abacus-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\abacus.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=no
RestartApplications=no
UsePreviousAppDir=no

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{userprograms}\Abacus"; Filename: "{app}\abacus.exe"

[Run]
Filename: "{app}\abacus.exe"; Description: "Launch Abacus"; Flags: nowait postinstall skipifsilent
