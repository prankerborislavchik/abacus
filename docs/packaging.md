# Установщики Abacus

Практика №4 использует нативные установочные пакеты из release-сборки: macOS Installer `.pkg`, Windows Inno Setup `.exe` и Debian `.deb`. Версия берётся из `pubspec.yaml`; полный Flutter bundle, движок и ресурсы входят в пакет. Сначала выполни настройку из [README](../README.md), проверки и release-сборку на целевой ОС.

| ОС | Команда упаковки | Готовый пакет | Установка |
| --- | --- | --- | --- |
| macOS | `bash scripts/package.sh macos` | `dist/abacus-macos.pkg` | `~/Applications/Abacus.app` |
| Windows x64 | `pwsh -File scripts/package-windows.ps1` | `dist/abacus-windows-setup.exe` | `%LOCALAPPDATA%\Programs\Abacus` |
| Linux x64 / arm64 | `bash scripts/package.sh linux` | `dist/abacus-linux.deb` | `/opt/abacus`, команда `abacus`, меню приложений |

Скрипты упаковки используют уже собранное приложение, не запускают Flutter и не загружают инструменты. Рядом с пакетом создаются список файлов и SHA-256. `build/` и `dist/` исключены из Git. Автоматический цикл с получением исходников, сборкой, тестами, установкой и проверкой запуска описан в [CI](ci.md).

## macOS

Нужны Xcode и штатные `pkgbuild`, `productbuild`, `installer`.

```sh
fvm flutter build macos --release
bash scripts/package.sh macos
bash scripts/install.sh macos dist/abacus-macos.pkg
open "$HOME/Applications/Abacus.app"
```

Пакет устанавливается штатным Installer в `CurrentUserHomeDirectory` без `sudo`, оставляя receipt `io.github.prankerborislavchik.abacus` в пользовательском домене. Его также можно открыть в графическом Installer. Архитектуры и минимальная macOS берутся из собранного приложения; локальная стандартная Flutter-сборка содержит arm64 и x86_64. Неизвестные архитектуры, неверный bundle ID и устаревшая версия сборки отклоняются.

`install.sh` сначала проверяет домен и содержимое пакета, затем вызывает `installer`, проверяет подпись целостности, весь установленный bundle и receipt. Проверить receipt отдельно:

```sh
pkgutil --volume "$HOME" --pkg-info io.github.prankerborislavchik.abacus
```

Для проверки чистой установки скрипт отказывается заменять существующий `~/Applications/Abacus.app`. Перед повтором закрой приложение и перемести старую копию в другую папку. Графический Installer может обновлять приложение штатно. Перемещение установленного приложения в Корзину удаляет программу; receipt сам по себе приложение не запускает и не занимает существенного места.

Пакет не подписан Developer ID и не нотарифицирован. Проверяемая `codesign` подпись Flutter подтверждает целостность bundle, но не доверие Apple к издателю. При скачивании macOS может потребовать отдельного разрешения пользователя. Скрипты не меняют Gatekeeper и quarantine.

## Windows

Для упаковки дополнительно нужны PowerShell 7 и [Inno Setup 6](https://jrsoftware.org/isinfo.php), доступный через `ISCC.exe` в PATH или стандартный каталог `Program Files (x86)\Inno Setup 6`. Visual Studio C++ workload должен включать redistributable CRT. Устанавливать Flutter или Visual Studio получателю пакета не нужно.

```powershell
fvm flutter build windows --release
pwsh -File scripts/package-windows.ps1
pwsh -File scripts/install-windows.ps1 -PackagePath dist/abacus-windows-setup.exe
& "$env:LOCALAPPDATA\Programs\Abacus\abacus.exe"
```

Inno Setup работает для текущего пользователя, создаёт пункт меню «Пуск» и регистрацию удаления. Пакет можно открыть двойным щелчком; скрипт запускает его с `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`, проверяет код завершения, регистрацию версии, ярлык и SHA-256 установленных файлов. Существующую установку скрипт не перезаписывает: сначала используй «Установленные приложения» → Abacus → «Удалить».

Runtime DLL копируются только из `VC/Redist/MSVC/.../x64/Microsoft.VC*.CRT` выбранной Visual Studio, а не из системных папок. При нестандартной установке передай `-VcRedistDirectory <каталог-CRT>`. App-local DLL позволяют оставить установку без административных прав; при обновлении runtime нужно пересобрать и переустановить пакет. Это соответствует [инструкции Flutter по Windows](https://docs.flutter.dev/platform-integration/windows/building) и [описанию Microsoft redistributable DLL](https://learn.microsoft.com/en-us/cpp/windows/determining-which-dlls-to-redistribute?view=msvc-170). Пакет не имеет сертификата подписи издателя.

## Linux

Упаковка рассчитана на Debian/Ubuntu с `dpkg-dev`; release-сборку выполняй на том поколении дистрибутива, которое планируешь поддерживать. Runtime-зависимости и их минимальные версии вычисляются `dpkg-shlibdeps` по ELF-файлам. Поэтому пакет, собранный на Ubuntu 24.04, нельзя считать совместимым с более старой Ubuntu без отдельной проверки.

```sh
sudo apt-get install -y dpkg-dev
fvm flutter build linux --release
bash scripts/package.sh linux
bash scripts/install.sh linux dist/abacus-linux.deb
abacus
```

Установка использует `apt-get install <полный-путь-к-пакету>` и требует права администратора. APT устанавливает объявленные runtime-зависимости. Проверяются регистрация пакета, версия, файлы, symlink команды и desktop entry. Для повторной проверки чистой установки сначала выполни `sudo apt-get remove abacus`. Для запуска нужен графический сеанс; CI проверяет запуск через Xvfb.

## Что подтверждает проверка

Успешный `package` подтверждает создание установщика; успешный `install` — работу нативного установщика и состав установленного приложения. Проверка запуска в CI отдельно запускает именно установленный исполняемый файл. Она не заменяет ручную проверку вычислений и интерфейса на компьютере сокомандника. Минимальная ручная проверка: установить пакет, открыть Abacus из меню приложений, посчитать `2+3*4`, `sin(30)` в DEG, выполнить M+ → AC → MR и закрыть окно.
