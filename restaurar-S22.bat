@echo off
rem Desfaz as mudancas feitas no Galaxy S22. Usa o adb ao lado do script
rem (pasta platform-tools) ou o que estiver no PATH.
set ADB=adb
if exist "%~dp0platform-tools\adb.exe" set ADB="%~dp0platform-tools\adb.exe"

%ADB% shell settings put global private_dns_mode opportunistic
%ADB% shell settings put global wifi_scan_always_enabled 1
%ADB% shell settings put global ble_scan_always_enabled 1
%ADB% shell appops set com.android.chrome REQUEST_INSTALL_PACKAGES allow
%ADB% shell appops set com.brave.browser REQUEST_INSTALL_PACKAGES allow
%ADB% shell settings put global window_animation_scale 1.0
%ADB% shell settings put global transition_animation_scale 1.0
%ADB% shell settings put global animator_duration_scale 1.0
%ADB% shell settings put secure edge_enable 1

for %%P in (
  com.microsoft.appmanager
  com.facebook.appmanager
  com.facebook.services
  com.facebook.system
  com.samsung.android.rubin.app
  com.samsung.android.dqagent
  com.sec.android.diagmonagent
  com.samsung.android.ipsgeofence
  com.samsung.android.app.taskedge
  com.samsung.android.app.clipboardedge
  com.samsung.android.app.spage
  com.sec.android.autodoodle.service
  com.samsung.android.stickercenter
  com.samsung.storyservice
  com.samsung.android.dynamiclock
  com.samsung.android.widget.pictureframe
  com.samsung.android.smartswitchassistant
  com.sec.android.easyMover.Agent
  com.samsung.android.kidsinstaller
  com.samsung.android.app.parentalcare
  com.samsung.SMT.lang_es_mx_f00
  com.samsung.SMT.lang_en_us_l03
  com.samsung.android.smartmirroring
  com.samsung.android.allshare.service.mediashare
  com.samsung.android.mdx.kit
  com.sec.android.daemonapp
) do %ADB% shell cmd package install-existing %%P

echo Restaurado. Reinicie o celular.
