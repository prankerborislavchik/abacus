# Abacus

Калькулятор на Flutter и Dart для macOS, Windows и Linux.

Сейчас доступен **графический каркас**: поле выражения, результат, клавиатура, индикатор памяти и компонент сообщения об ошибке/предупреждении. Поле доступно только для чтения, кнопки отключены. Ввод, валидация, вычисление по `=` и память ещё не реализованы.

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

В `.vscode/` хранятся только общие рекомендации расширений и путь к SDK `.fvm/flutter_sdk`. Редактор можно выбрать любой; личные настройки IDE в Git не добавляем. Во всех терминальных командах используй префикс `fvm`.

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

**Валидация, вычисление по `=` и память включают unit-тесты в том же PR**. Автор реализации выбирает сценарии и пишет тесты обычных, граничных и ошибочных случаев. Ревьюер проверяет соответствие критериям issue и полноту проверок. Если обязательных тестов нет, дорабатываем тот же PR до закрытия задачи.

`flutter_test` уже подключён. Тесты функций и классов размещаем в `test/calculator/`, в файлах `*_test.dart`, используя `test`, `group` и `expect` из `package:flutter_test/flutter_test.dart`. [Официальный пример unit-теста](https://docs.flutter.dev/cookbook/testing/unit/introduction) показывает этот подход. Запуск — `fvm flutter test`.

Тестовых файлов пока нет. PR с первыми тестами добавляет шаг `flutter test` в job `Quality`.

В [GitHub Actions](https://github.com/prankerborislavchik/abacus/actions) на каждом PR и изменении `main` запускаются форматирование, анализ и release-сборки macOS, Windows, Linux. SDK для CI берётся из той же `.fvmrc`.

Успешные сборки сохраняются в artifacts запуска CI на 7 дней. Это архивы приложения, без установщика и подписи для распространения. Сборка в CI подтверждает компиляцию; интерфейс проверяй нативным запуском на целевой ОС.

Локальную release-сборку выполняй на соответствующей ОС:

```sh
fvm flutter build macos --release
fvm flutter build windows --release
fvm flutter build linux --release
```

## Работа в команде

Задачи, ответственные и критерии готовности живут в GitHub Issues. Изменения проходят через короткую ветку от актуального `main` → PR → ревью → merge. Стремимся вливать небольшие изменения каждый день или два; подробнее — [trunk-based development с короткими ветками](https://trunkbaseddevelopment.com/short-lived-feature-branches/).

```sh
git fetch origin
git switch -c feat/12-expression-validation origin/main
# Работа, проверки и коммиты
git push -u origin feat/12-expression-validation
```

Перед завершением PR обнови свою ветку: `git fetch origin`, затем `git rebase origin/main` и повторные проверки. Для уже опубликованной своей ветки после rebase используй `git push --force-with-lease`. `main` не переписываем.

В PR укажи issue, изменения и результаты проверок; `Closes #12` добавляй, когда задача выполнена целиком. Для merge нужны успешные проверки и одобрение другого участника. Используем **Create a merge commit**, чтобы сохранить историю коммитов.

### Коммиты: MCGA

Используем [MCGA от h1km4t1ll0](https://github.com/h1km4t1ll0/make-commits-great-again), уже основанный на [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Сообщения пишем **по-английски**: обычный префикс (`feat:`, `fix:`, `docs:` и т. д.), энергичный заголовок с CAPS и `!`, точное описание изменения. Имена файлов и API сохраняем как в коде; стандартные merge-сообщения оставляем обычными.

```text
docs: Setup instructions are FINALLY Clear!

The installation steps were missing. Now README explains the SDK and native prerequisites. Ready to build!
```

Skill — необязательный помощник для составления сообщения: [установка](https://github.com/h1km4t1ll0/make-commits-great-again#install). Конвенция действует и при ручных коммитах.

## Структура проекта

- [Архитектура калькулятора](docs/architecture.md)
- [Термины калькулятора](CONTEXT.md)
- [Инструкции для агентов](AGENTS.md)
- [Шаблон задачи](.github/ISSUE_TEMPLATE/task.yml) и [шаблон PR](.github/pull_request_template.md)

При изменении SDK обновляй `.fvmrc` через `fvm use <версия>`, затем зависимости и `pubspec.lock` в одном PR. Lockfile приложения хранится в Git; SDK, кеши и сборки — в игнорируемых каталогах.
