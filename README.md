# Celular Android mais limpo, privado e leve

Guia e prompt para diagnosticar e limpar um celular Android pelo computador, sem root. O projeto procura sinais de vírus e de rastreamento, explica por que os anúncios "seguem" você mesmo no modo anônimo, mede a saúde da bateria, remove o excesso de software de fábrica por ADB e confere o resultado com medidas antes e depois.

Foi feito e testado em um **Samsung Galaxy S22 (SM-S901E)** com Android 16, One UI 8.0 e Snapdragon 8 Gen 1, em outubro de 2026. Em outros modelos, use o [prompt com varredura](#usar-com-um-agente-de-ia) e adapte o que for diferente.

Inspirado em [cavaleiro-ai/Tirando-defeito-programado-dos-tablets](https://github.com/cavaleiro-ai/Tirando-defeito-programado-dos-tablets), que faz o mesmo para tablets voltados a jogos. Este projeto troca o foco: **segurança, privacidade, armazenamento, câmera e bateria** em um celular de uso diário, com chip, conta Google e conta Samsung.

## Conteúdo

- [Resultados medidos](#resultados-medidos)
- [O que a varredura encontrou](#o-que-a-varredura-encontrou)
- [Por que os anúncios seguem você no modo anônimo](#por-que-os-anúncios-seguem-você-no-modo-anônimo)
- [Por que a lista de um tablet não serve para um celular](#por-que-a-lista-de-um-tablet-não-serve-para-um-celular)
- [O que há no repositório](#o-que-há-no-repositório)
- [Requisitos](#requisitos)
- [Passo a passo resumido](#passo-a-passo-resumido)
- [Ajustes que só você faz no celular](#ajustes-que-só-você-faz-no-celular)
- [Usar com um agente de IA](#usar-com-um-agente-de-ia)
- [Problemas comuns](#problemas-comuns)
- [Limites](#limites)
- [Fontes](#fontes)

## Resultados medidos

Medidas feitas pelo ADB, com o celular parado. O "depois" foi medido 2 minutos após reiniciar.

| Medida | Antes | Depois |
| --- | --- | --- |
| Apps ativos | 513 | 478 |
| Espaço livre | 81 GB | 98 GB (103 GB no fim do dia) |
| RAM disponível | 2,87 GB | 3,47 GB |
| Abrir Configurações (3 vezes) | 425 / 353 / 280 ms | 613 / 183 / 278 ms |
| DNS com bloqueio de anúncios | configurado, mas inativo | ativo e validado |
| Busca de Wi-Fi e Bluetooth em segundo plano | ligada | desligada |

O ganho mais sólido é o **espaço livre**: 15,8 GB vieram só da limpeza de cache. A RAM sobe naturalmente logo depois de reiniciar, então parte desse ganho é do reinício. A primeira abertura de um app depois de reiniciar é sempre mais lenta (613 ms). Não houve benchmark, então este projeto não promete um percentual de velocidade.

Situação de cada parte:

| Parte | Situação | Evidência |
| --- | --- | --- |
| Varredura de segurança | Funciona | Rodou de ponta a ponta no S22 |
| Remoção de 38 pacotes | Funciona | Tela inicial respondeu depois de cada grupo; celular reiniciou normalmente |
| DNS privado AdGuard | Funciona | Validado pelo Android e com internet ativa |
| Compilação dos apps | Funciona | `compile -m speed-profile -a` em 4 minutos, sem erro |
| Ligação, SMS, câmera, Quick Share após as remoções | Não testado pelo ADB | Testar no uso |
| Efeito sobre anúncios | Não medido | Precisa de alguns dias de observação |
| Dreno da bateria com a tela apagada | Não medido | |
| Pasta Segura | Fora do alcance | O ADB não tem acesso a ela |

## O que a varredura encontrou

O sistema estava **original e íntegro**: bootloader travado, inicialização verificada "green", Knox nunca violado. Não havia proxy, VPN, serviço de acessibilidade nem administrador de dispositivo estranho. Isso torna improvável um vírus "dentro" do Android. O que apareceu estava em apps, permissões e configurações:

| Achado | Gravidade | O que foi feito |
| --- | --- | --- |
| DNS da AdGuard configurado, mas com o modo em "Automático", ou seja, sem bloquear nada | Atenção | Modo trocado para nome do host `dns.adguard-dns.com` |
| App de "recuperar mensagens apagadas" com acesso a **todas as notificações**, inclusive códigos de banco | Grave | Removido |
| 9 extensões de um leitor de mangá instaladas fora da loja, sem o app principal | Atenção | Removidas |
| APK de 103 MB baixado pelo navegador fora da loja, e navegador com permissão para instalar apps | Atenção | APK apagado; permissão de instalar apps tirada do Chrome e do Brave |
| Pasta de um app conhecido por fraude de anúncios, já desinstalado | Informativo | Pasta apagada |
| Serviços de fábrica da Meta, personalização e telemetria da Samsung | Atenção | Removidos |
| Bateria com saúde de **85%**, temperatura máxima registrada de **63,7 °C** e proteção da bateria desligada | Atenção | Proteção ligada pelo usuário; troca ainda não é necessária |
| 16,8 GB de cache | Informativo | Limpo com `pm trim-caches` |

Sobre as fotos piores: não havia erro de câmera no registro do sistema. O app Câmera foi atualizado junto com o One UI 8, o que pode ter mudado o processamento de imagem. Calor e bateria desgastada também reduzem o desempenho da câmera. Nenhuma das hipóteses foi provada.

## Por que os anúncios seguem você no modo anônimo

O modo anônimo apaga histórico e cookies **do aparelho** quando você fecha a aba. Ele não impede:

- **Login na conta Google** ou pesquisa no Google dentro da aba anônima. A pesquisa fica registrada na conta.
- **Personalização por conta.** O ID de publicidade do Google e o perfil da Samsung ligam o que você faz em apps aos anúncios.
- **IP.** Sites e anunciantes reconhecem a sua internet pelo IP. Um DNS com bloqueio reduz rastreadores, mas não esconde o IP. Para isso é preciso VPN.
- **Apps que rastreiam bastante.** Lojas e redes sociais costumam carregar vários SDKs de anúncio.
- **Proxy, VPN, certificado instalado ou app com acessibilidade.** Esses conseguem ver o tráfego. A varredura confere cada um.

## Por que a lista de um tablet não serve para um celular

A lista do projeto original foi feita para um tablet **sem chip e sem conta Google**. No S22, quase metade dos pacotes dela nem existe mais no One UI 8, e vários são necessários:

| Pacote | Por que fica no celular |
| --- | --- |
| `com.samsung.android.messaging` | É o app de SMS padrão |
| `scloud`, `mobileservice` | Conta Samsung, backup e Samsung Wallet |
| `scs` | Busca e recursos de IA do One UI 8 |
| `knox.attestation`, `knox.app.networkfilter`, `knox.analytics.uploader` | Wallet, Samsung Pass e apps de banco verificam a segurança do aparelho pelo Knox |
| `sharelive`, `aware.service` | Quick Share |
| `forest` | Bem-estar digital; o modo Dormir do Modos e Rotinas depende dele |
| `app.routines` | Modos e Rotinas |
| `mimage.photoretouching` | Editor de fotos da Galeria |
| `themecenter`, `dressroom` | Temas e papéis de parede |
| `game.gos`, `smartfpsadjuster` | Seguram o calor; num aparelho que já chegou a 63,7 °C, removê-los piora |

A lista completa do que saiu está em [`removidos-S22.txt`](removidos-S22.txt).

## O que há no repositório

| Caminho | Conteúdo |
| --- | --- |
| `Prompt-celular-diagnostico-e-limpeza.txt` | Prompt para um agente diagnosticar e limpar qualquer celular Android, com a referência do S22 no final |
| `Tutoriais/Passo-a-passo-Galaxy-S22.md` | Todos os comandos usados no S22, na ordem, com o que cada um mostrou e os problemas encontrados |
| `removidos-S22.txt` | Os pacotes removidos do S22, com a função de cada um |
| `restaurar-S22.bat` | Desfaz as configurações e reinstala os pacotes de sistema removidos |

## Requisitos

- Celular Android com **Depuração USB** ligada.
- Computador com o [ADB oficial](https://dl.google.com/android/repository/platform-tools-latest-windows.zip). O script `.bat` é para Windows.
- Cabo USB de dados.
- Backup das fotos e conversas antes de remover qualquer coisa.

## Passo a passo resumido

Detalhes e saídas em [`Tutoriais/Passo-a-passo-Galaxy-S22.md`](Tutoriais/Passo-a-passo-Galaxy-S22.md).

```bash
# Conexão
adb devices -l

# Segurança (só leitura)
adb shell getprop ro.build.version.security_patch
adb shell getprop ro.boot.verifiedbootstate        # green = sistema original
adb shell pm list packages -i -3 --user 0           # apps e de onde vieram
adb shell settings get secure enabled_accessibility_services
adb shell settings get secure enabled_notification_listeners
adb shell appops query-op REQUEST_INSTALL_PACKAGES allow
adb shell settings get global http_proxy
adb shell settings get global private_dns_mode
adb shell dumpsys device_policy

# Bateria (Samsung mostra saúde e temperatura máxima aqui)
adb shell dumpsys battery

# Guardar a lista atual e remover um pacote só do usuário principal
adb shell pm list packages -e --user 0 > antes.txt
adb shell pm uninstall --user 0 NOME.DO.PACOTE

# DNS com bloqueio de anúncios
adb shell settings put global private_dns_specifier dns.adguard-dns.com
adb shell settings put global private_dns_mode hostname

# Menos rastreio de localização e menos bateria
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global ble_scan_always_enabled 0

# Animações mais curtas, cache e compilação
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
adb shell pm trim-caches 999G
adb shell cmd package compile -m speed-profile -a

adb reboot
```

**Para reverter um pacote:** `adb shell cmd package install-existing NOME.DO.PACOTE`, ou rode `restaurar-S22.bat`.

Não remova o app de SMS, o telefone, a loja de apps, o Google Play Services, o teclado, o Knox nem nada ligado a banco ou carteira digital.

## Ajustes que só você faz no celular

O ADB não alcança estes, ou é mais seguro fazer pela tela:

1. **Proteção da bateria:** Configurações → Bateria → Proteção da bateria → Adaptável ou Máximo (80%).
2. **ID de publicidade:** Configurações → Google → Todos os serviços → Anúncios → Excluir ID de publicidade.
3. **Certificados:** Segurança e privacidade → Mais configurações de segurança → Ver certificados de segurança → aba Usuário. Certificado que você não instalou permite ler o seu tráfego.
4. **Play Protect:** Play Store → foto do perfil → Play Protect → Verificar.
5. **Câmera:** limpar a lente, conferir a película e, em Apps → Câmera → Armazenamento, Limpar cache.
6. **Navegador (Brave):** ⋮ → Configurações → Escudos e privacidade → Limpar dados de navegação (Todo o período). Bloqueio de rastreadores em Agressivo, bloqueio de fingerprinting ligado, P3A, ping diário e relatórios de diagnóstico desligados. Não use "Limpar dados" na tela do app, que apaga senhas e favoritos.
7. **Conta Google:** myactivity.google.com para apagar pesquisas, e desligar Atividade na Web e de apps.

## Usar com um agente de IA

O [`Prompt-celular-diagnostico-e-limpeza.txt`](Prompt-celular-diagnostico-e-limpeza.txt) começa com uma varredura só de leitura, mostra um relatório com as causas prováveis de cada sintoma e só muda algo depois da sua aprovação, item por item. Preencha a parte `DADOS` e cole em um agente com acesso ao terminal do computador ligado ao celular.

O processo foi executado de ponta a ponta só no Galaxy S22.

## Problemas comuns

| Problema | Solução |
| --- | --- |
| `adb devices` vazio, mas o Windows mostra o celular | A Depuração USB está desligada. Ative e aceite o aviso no celular |
| `Shell does not have permission to access user 150` | É a Pasta Segura. Use sempre `--user 0` nos comandos `pm` |
| `DELETE_FAILED_INTERNAL_ERROR` ao remover um app | O app também está na Pasta Segura. Ele sai do usuário principal mesmo assim; confira com `pm list packages --user 0` e apague pela Pasta Segura |
| `df` ou `du` com caminho `C:/Program Files/Git/...` | O Git Bash converteu o caminho. Rode com `MSYS_NO_PATHCONV=1` |
| `find /sdcard` não encontra nada | `/sdcard` é um atalho. Use `/storage/emulated/0/` |
| `bg-dexopt-job` termina com "Job cancelled" | O celular não estava ocioso. Use `cmd package compile -m speed-profile -a` |
| Tamanhos de `dumpsys diskstats` não mudam após limpar | Os tamanhos por app são recalculados uma vez por dia. Compare o `Data-Free` |
| Um app removido fez falta | `adb shell cmd package install-existing NOME.DO.PACOTE` |
| Apps removidos voltaram | Uma atualização do sistema pode reinstalá-los. Remova de novo |

## Limites

- **ADB não é antivírus.** Ele mostra indícios. Não encontrar nada não prova que o aparelho está limpo.
- A Pasta Segura e os dados internos dos apps, como histórico de navegação, não podem ser lidos sem root.
- Este guia não faz root, não desbloqueia o bootloader e não grava ROM.
- Se houver app malicioso confirmado ou os sinais voltarem: troque as senhas **a partir de outro aparelho**, ative verificação em duas etapas, faça backup e considere restaurar o celular para o padrão de fábrica.

## Fontes

- [ADB, documentação oficial do Android](https://developer.android.com/tools/adb)
- [Configuração do ART e filtros de compilação](https://source.android.com/docs/core/runtime/configure)
- [Universal Android Debloater Next Generation](https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation), lista pública usada para identificar pacotes
- [AdGuard DNS](https://adguard-dns.io/)
- [Projeto original para tablets](https://github.com/cavaleiro-ai/Tirando-defeito-programado-dos-tablets)
