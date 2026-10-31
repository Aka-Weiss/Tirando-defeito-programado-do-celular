# Galaxy S22: diagnóstico, privacidade e limpeza por ADB

Registro do que foi feito em um Samsung Galaxy S22 em 31/10/2026, na ordem, com o que cada etapa mostrou. Identificadores do aparelho (número de série, rede Wi-Fi, IPs) foram retirados.

## Visão geral

| Item | Valor |
| --- | --- |
| Modelo | Galaxy S22, SM-S901E (codinome r0q) |
| Chip | Qualcomm Snapdragon 8 Gen 1 (SM8450, plataforma taro) |
| Sistema | Saiu com Android 12; hoje Android 16, One UI 8.0, build de 18/08/2026 |
| Patch de segurança | 2026-08-05 |
| Região | Brasil (CSC ZTO, multi-CSC OWO) |
| Integridade | Bootloader travado, verified boot green, Knox warranty bit 0 |
| Uso | Chip, conta Google, conta Samsung, Samsung Wallet, Pasta Segura |
| Sintomas | Anúncios ligados à navegação anônima, fotos piores, travamentos, armazenamento; há cerca de 3 meses |

## Conexão ADB

```bash
adb devices -l
```

Primeiro veio vazio. O Windows mostrava o celular como "SAMSUNG Mobile USB Composite Device", MTP e modem (`Get-PnpDevice`, VID_04E8), ou seja, o driver estava certo e só faltava a **Depuração USB**. Depois de ativar e aceitar o aviso no celular:

```
RXXXXXXXXXX  device product:r0qxxx model:SM_S901E device:r0q
```

No Git Bash do Windows, exporte `MSYS_NO_PATHCONV=1`. Sem isso, `adb shell df -h /data` vira `C:/Program Files/Git/data`.

## Varredura

### Apps

```bash
adb shell pm list packages -i -3 --user 0
```

Sem `--user 0`, todos os comandos `pm` falharam com `Shell does not have permission to access user 150`: o usuário 150 é a Pasta Segura.

- 513 pacotes ativos, 462 de sistema, 81 de terceiros.
- Instalador `null`: 9 extensões de um leitor de mangá. `dumpsys package` mostrou `initiatingPackageName=app.mihon`, um app que já não estava instalado, ou seja, eram órfãs.
- Instalados por APK (`com.google.android.packageinstaller`): dois apps conhecidos e usados pelo dono, um deles desatualizado desde 2024.

### Poderes perigosos

```bash
adb shell settings get secure enabled_accessibility_services     # null
adb shell settings get secure enabled_notification_listeners
adb shell appops query-op SYSTEM_ALERT_WINDOW allow
adb shell appops query-op REQUEST_INSTALL_PACKAGES allow
adb shell dumpsys device_policy
```

- Acessibilidade: nenhum serviço.
- Leitura de notificações: Android Auto, a tela inicial da Samsung e um app de "recuperar mensagens apagadas". Esse último vê todas as notificações, inclusive códigos de banco.
- Instalar apps: Downloads, Meus Arquivos, Chrome, Brave e um app de download. `cmd appops get com.brave.browser REQUEST_INSTALL_PACKAGES` mostrou que o Brave tinha sido liberado havia 5 dias.
- Admins: só o Knox Guard da Samsung (`kgclient`) no usuário 0 e o Knox da Pasta Segura no usuário 150. Normal.

### Rede

```bash
adb shell settings get global http_proxy            # null
adb shell settings get global private_dns_mode      # opportunistic
adb shell settings get global private_dns_specifier # dns.adguard.com
adb shell dumpsys connectivity
```

Sem proxy e sem VPN. O DNS da AdGuard estava **configurado, mas inativo**: com o modo em `opportunistic` ("Automático"), o Android ignora o nome do host e usa o DNS da rede.

### Bateria

```bash
adb shell dumpsys battery
adb shell dumpsys batterystats --charged
adb shell dumpsys thermalservice
```

O `dumpsys battery` da Samsung trouxe mais do que o Android padrão:

| Campo | Valor | Significado |
| --- | --- | --- |
| `mSavedBatteryAsoc` | 85 | Saúde da bateria: 85% |
| `FirstUseDate` | 20240125 | Primeiro uso da bateria |
| `mSavedBatteryMaxTemp` | 637 | Temperatura máxima registrada: 63,7 °C |
| `mProtectBatteryMode` | 0 | Proteção da bateria desligada |
| `health` | 2 | "Good" para o Android |

Os arquivos em `/sys/class/power_supply/battery/` deram `Permission denied`. O `batterystats` estimou 3.590 mAh de capacidade, contra 3.700 mAh de fábrica. Os apps que mais gastaram bateria foram os que estavam em uso; nenhum gastava escondido em segundo plano.

### Armazenamento

```bash
adb shell df -h /data
adb shell dumpsys diskstats
adb shell "du -s -m /storage/emulated/0/*"
```

77% ocupado. Os maiores: downloads offline de um app de música (30 GB), DCIM (33 GB) e 16,8 GB de cache. O `sort -h` não existe no Android, e `find /sdcard` não acha nada porque `/sdcard` é um atalho: use `/storage/emulated/0/`.

### Câmera

```bash
adb shell "pm list packages --user 0 | grep -iE 'camera|photo|retouch|gallery'"
adb shell "logcat -d -t 3000 | grep -i camera"
```

App Câmera 16.0.00.66, vindo com o One UI 8. Nenhum erro de câmera no log.

## Permissões e configurações alteradas

```bash
adb shell settings put global private_dns_specifier dns.adguard-dns.com
adb shell settings put global private_dns_mode hostname
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global ble_scan_always_enabled 0
adb shell appops set com.android.chrome REQUEST_INSTALL_PACKAGES deny
adb shell appops set com.brave.browser REQUEST_INSTALL_PACKAGES deny
adb shell settings put secure edge_enable 0
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

O DNS foi conferido em `dumpsys connectivity` (`PrivateDnsServerName: dns.adguard-dns.com`, endereço validado) e com `ping`. O endereço validado não era o IP mais conhecido da AdGuard, então ele foi conferido resolvendo o nome no computador por outro DNS: o resultado foi o mesmo.

## Remoção

Feita em grupos, com aprovação de cada pacote e conferência da tela inicial depois de cada grupo:

```bash
adb shell pm uninstall --user 0 PACOTE          # sistema: volta com install-existing
adb shell pm uninstall PACOTE                   # terceiro: só volta pela loja
adb shell dumpsys window | grep mCurrentFocus   # deve mostrar a tela inicial
```

Lista completa em [`../removidos-S22.txt`](../removidos-S22.txt).

O app que lia notificações deu `DELETE_FAILED_INTERNAL_ERROR`, mas saiu do usuário principal (`pm list packages --user 0` não o mostrava mais). O erro indica que ele continua instalado na Pasta Segura, que só o dono consegue limpar.

Arquivos apagados com aprovação: um APK de 103 MB baixado fora da loja e a pasta de um app de download já desinstalado. Prints de tela relacionados foram **mantidos** a pedido do dono. Um erro: o APK foi apagado sem antes calcular o SHA-256, o que impediu checar se era original.

## Cache, compilação e reinício

```bash
adb shell pm trim-caches 999G                    # Data-Free: 86,9 GB -> 102,7 GB
adb shell cmd package bg-dexopt-job              # "Job cancelled" após 29 s
adb shell cmd package compile -m speed-profile -a  # 244 s, sem erro
adb reboot
```

O `bg-dexopt-job` foi cancelado pelo próprio Android, provavelmente porque o celular não estava ocioso. A compilação direta funcionou.

## Resultados

| Medida | Antes | Depois |
| --- | --- | --- |
| Apps ativos | 513 | 478 |
| Espaço livre | 81 GB | 98 GB |
| RAM disponível | 2,87 GB | 3,47 GB |
| Abrir Configurações | 425 / 353 / 280 ms | 613 / 183 / 278 ms |

Depois do reinício, DNS, scans, animações, painéis Edge e permissões continuavam como configurados, e o app que lia notificações não aparecia mais na lista de leitores.

## Problemas encontrados

| Problema | Causa | Solução |
| --- | --- | --- |
| `adb devices` vazio | Depuração USB desligada | Ativar e aceitar o aviso |
| `access user 150` | Pasta Segura | `--user 0` |
| Caminhos `C:/Program Files/Git/...` | Conversão do Git Bash | `MSYS_NO_PATHCONV=1` |
| `find /sdcard` sem resultado | `/sdcard` é atalho | `/storage/emulated/0/` |
| `sort -h` inexistente | toybox do Android | Ordenar no computador |
| Tamanho do cache não mudava no `diskstats` | Recalculado uma vez por dia | Comparar `Data-Free` |
| `DELETE_FAILED_INTERNAL_ERROR` | App também na Pasta Segura | Conferir `--user 0` e limpar a Pasta Segura no celular |
| `bg-dexopt-job` cancelado | Celular não ocioso | `compile -m speed-profile -a` |
| Comparação de "consumo do cache do Brave" pelo ADB | Dados internos protegidos sem root | Ler Configurações → Apps → Brave → Armazenamento na tela (`uiautomator dump`) |

## Navegador

O histórico e os cookies do Brave não podem ser lidos pelo ADB sem root. A limpeza foi feita no próprio app (Escudos e privacidade → Limpar dados de navegação → Todo o período), e a tela de armazenamento do app foi lida pelo ADB com:

```bash
adb shell uiautomator dump /data/local/tmp/ui.xml
adb shell cat /data/local/tmp/ui.xml
adb shell rm /data/local/tmp/ui.xml
```

Resultado: aplicativo 286 MB, dados 66 MB, cache 60 MB, valores normais depois da limpeza.
