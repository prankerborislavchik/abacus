# Abacus

Учебный калькулятор на Flutter и Dart для macOS, Windows и Linux.

Сейчас доступен **графический каркас**: поле выражения, результат, клавиатура, индикатор памяти и компонент сообщения об ошибке/предупреждении. Поле доступно только для чтения, кнопки отключены. Ввод, валидация, вычисление по `=` и память — следующие задачи команды.

## Установка

Нужны Git, [FVM](https://fvm.app/documentation/getting-started/installation) и инструменты сборки для своей ОС. Версия Flutter закреплена в [.fvmrc](.fvmrc); Dart входит в этот SDK и отдельно не устанавливается.

Установи FVM по официальной инструкции для своей ОС. На macOS с Homebrew:

```sh
brew install fvm
```

На Windows с уже установленным Chocolatey:

```powershell
choco install fvm
```

Для Linux и установки без пакетного менеджера доступны [официальный установщик и standalone-пакеты FVM](https://fvm.app/documentation/getting-started/installation). Проверь, что `fvm --version` работает в новом терминале.

### Нативные инструменты

| ОС | Что установить |
| --- | --- |
| macOS | Полный Xcode, его начальные компоненты и лицензии; [инструкция Flutter](https://docs.flutter.dev/platform-integration/macos/setup). Одних Command Line Tools недостаточно. |
| Windows | Visual Studio с workload **Desktop development with C++** и Windows SDK; [инструкция Flutter](https://docs.flutter.dev/platform-integration/windows/setup). VS Code можно использовать как редактор, но инструменты C++ устанавливаются через Visual Studio. |
| Linux | Clang, CMake, Ninja, pkg-config, GTK 3 development headers и libstdc++; [инструкция Flutter](https://docs.flutter.dev/platform-integration/linux/setup). |

Для Ubuntu/Debian:

```sh
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
```

### Первый запуск

```sh
git clone https://github.com/prankerborislavchik/abacus.git
cd abacus
fvm install
fvm flutter pub get --enforce-lockfile
fvm flutter doctor -v
fvm flutter devices
```

Исправь замечания `doctor` к выбранной desktop-платформе. Android SDK и iOS Simulator для этого проекта не нужны. При добавлении нативных плагинов могут понадобиться дополнительные инструменты, указанные в их документации.

Запускать нужно команду для своей ОС:

```sh
fvm flutter run -d macos
fvm flutter run -d windows
fvm flutter run -d linux
```

В VS Code рекомендуемые расширения указаны в [.vscode/extensions.json](.vscode/extensions.json), путь SDK — `.fvm/flutter_sdk`. Во всех терминальных командах используй префикс `fvm`.

Дополнительный web-preview интерфейса:

```sh
fvm flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357
```

Открой выданный локальный URL в браузере. Проверка desktop-приложения всё равно выполняется нативной сборкой и запуском.

## Проверки

Перед PR:

```sh
fvm dart format lib test
fvm dart format --output=none --set-exit-if-changed lib test
fvm flutter analyze --fatal-infos
```

`flutter_test` уже подключён. Тестовых файлов на этапе графического каркаса нет; `fvm flutter test` станет рабочей проверкой вместе с первыми тестами. Они обязательны в задачах валидации, `=` и памяти — см. [правила приёмки](docs/contributing.md#unit-тесты-и-приёмка).

В [GitHub Actions](https://github.com/prankerborislavchik/abacus/actions) на каждом PR и изменении `main` запускаются форматирование, анализ и release-сборки macOS, Windows, Linux. SDK для CI берётся из той же `.fvmrc`. Первый функциональный PR добавляет запуск unit-тестов в job `Quality`.

Успешные сборки сохраняются в artifacts запуска CI на 7 дней. Это архивы приложения, без установщика и подписи для распространения. Сборка в CI подтверждает компиляцию; настоящее окно Windows/Linux дополнительно проверяют участники на своих машинах.

Локальную release-сборку выполняй на соответствующей ОС:

```sh
fvm flutter build macos --release
fvm flutter build windows --release
fvm flutter build linux --release
```

Установщик и полный учебный цикл получения исходников, сборки, тестирования, упаковки и установки добавляются отдельными задачами.

## Работа в команде

Общий процесс — [короткая ветка → PR → ревью → merge](docs/contributing.md). Там же описаны trunk-based development, обновление ветки через rebase и приёмка тестов.

Используем **MCGA от h1km4t1ll0**, основанный на Conventional Commits; сообщения коммитов пишем по-английски. [Правила, пример и установка skill](docs/contributing.md#коммиты-mcga).

- [Структура кода и границы задач](docs/architecture.md)
- [Термины калькулятора](CONTEXT.md)
- [Инструкции для агентов](AGENTS.md) — единственный основной файл; отдельной копии правил в CLAUDE.md нет
- [Шаблон задачи](.github/ISSUE_TEMPLATE/task.yml) и [шаблон PR](.github/pull_request_template.md)

При изменении SDK обновляй `.fvmrc` через `fvm use <версия>`, затем зависимости и `pubspec.lock` в одном PR. Lockfile приложения хранится в Git; SDK, кеши и сборки — в игнорируемых каталогах.
