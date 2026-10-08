# lab-bigdata — «Анализ больших данных» на R / RStudio

[![R labs CI](https://github.com/Kennurken/lab-bigdata/actions/workflows/r-labs.yml/badge.svg)](https://github.com/Kennurken/lab-bigdata/actions/workflows/r-labs.yml)
![Windows](https://img.shields.io/badge/Windows-15%2F15%20labs%20in%20CI-0078D6?logo=windows&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-15%2F15%20labs%20in%20CI-FCC624?logo=linux&logoColor=black)
![macOS](https://img.shields.io/badge/macOS-15%2F15%20labs%20in%20CI-000000?logo=apple&logoColor=white)
![R](https://img.shields.io/badge/R-4.6-276DC3?logo=r&logoColor=white)

15 лабораторных работ: от основ R до Spark и машинного обучения. Код — `labNN.R`, результат запуска — `output.txt`, скриншоты — `screenshots/`, текст отчёта — `ЕСЕП.md` (на казахском).

| № | Папка | Тема | Что нужно кроме R-пакетов |
|---|-------|------|----------------------------|
| 01 | `lab01-r-negizderi` | Основы R | — |
| 02 | `lab02-derekter-qurylymdary` | Структуры данных | — |
| 03 | `lab03-import` | Импорт данных (CSV, Excel, JSON) | — |
| 04 | `lab04-tazalau` | Очистка данных | — |
| 05 | `lab05-dplyr` | dplyr | — |
| 06 | `lab06-statistika` | Статистика | — |
| 07 | `lab07-ggplot2` | ggplot2 | — |
| 08 | `lab08-korrelyaciya-regressiya` | Корреляция и регрессия | — |
| 09 | `lab09-r-sql` | R + SQL (SQLite) | — (SQLite встроен в пакет `RSQLite`) |
| 10 | `lab10-r-mongodb` | R + MongoDB | **запущенный MongoDB** на `127.0.0.1:27017` |
| 11 | `lab11-data-table` | data.table | — |
| 12 | `lab12-parallel` | Параллельные вычисления | — (на Windows часть про `mclapply` идёт в 1 поток) |
| 13 | `lab13-r-spark` | R + Spark (sparklyr) | **Java (JDK 17)** и локальный **Spark 3.5** |
| 14 | `lab14-ml` | Машинное обучение | — |
| 15 | `lab15-qorytyndy-joba` | Итоговый проект | — |

---

## 1. Что проверено, а что нет

| Среда | Статус |
|-------|--------|
| **macOS 27 (Apple Silicon), R 4.6.1, RStudio** (локально) | ✅ все 15 лаб выполнены без ошибок |
| **CI: Windows, Linux, macOS** (GitHub Actions, `windows-latest` / `ubuntu-latest` / `macos-latest`, актуальный R release) | ✅ при каждом пуше выполняются **все 15 лаб** через `run_lab.R`, включая MongoDB (лаба 10) и Spark (лаба 13). Workflow: [`.github/workflows/r-labs.yml`](.github/workflows/r-labs.yml) |

Что CI нашёл и что уже учтено:

- **Windows, лаба 13:** Spark требует **Visual C++ 2010 SP1 Redistributable** и **`winutils.exe`** — оба шага есть в CI и описаны в разделе 2.
- **Windows, лаба 12:** `mclapply` многоядерно не работает — скрипт выполняет эти шаги последовательно.
- **macOS-раннер, лаба 13:** один раз Spark не успел стартовать (`ignoring SIGPIPE signal` в `spark_connect`) и прошёл при повторе — это нехватка памяти на слабой машине (драйвер просит 4 ГБ), см. «Частые проблемы».

Тестировалось на версиях пакетов: `dplyr` 1.2.1, `ggplot2` 4.0.3, `data.table` 1.18.6.1, `DBI` 1.3.0, `RSQLite` 3.53.3, `mongolite` 4.1.0, `sparklyr` 1.9.5, `nycflights13` 1.0.2, `readxl` 1.5.0.1, `writexl` 2.0.1, `jsonlite` 2.0.0, `future` 1.76.0, `randomForest` 4.7-1.2, `rpart` 4.1.27, `tidyr` 1.3.2, `readr` 2.2.0. CI каждый раз ставит актуальные версии пакетов с CRAN, так что совместимость с новыми версиями тоже проверяется.

---

## 2. Что нужно установить (по ОС)

| Компонент | Нужен для | Windows 10/11 (64-бит) | macOS | Linux (Ubuntu 22.04+) |
|-----------|-----------|------------------------|-------|-----------------------|
| **R 4.6.1** (проверено) | всех лаб | https://cran.r-project.org/bin/windows/base/ | https://cran.r-project.org/bin/macosx/ (или `brew install --cask r`) | `sudo apt install r-base` или репозиторий CRAN |
| **RStudio Desktop** | удобная работа | https://posit.co/download/rstudio-desktop/ | то же | то же |
| **Rtools** (версия, соответствующая вашему R) | только если пакет придётся собирать из исходников | https://cran.r-project.org/bin/windows/Rtools/ | `xcode-select --install` | `sudo apt install build-essential libcurl4-openssl-dev libssl-dev libxml2-dev` |
| **Java JDK 17** | лаба 13 (Spark) | `winget install EclipseAdoptium.Temurin.17.JDK`, затем задать `JAVA_HOME` | `brew install openjdk@17` | `sudo apt install openjdk-17-jdk` |
| **MongoDB Community 8.x** | лаба 10 | `winget install MongoDB.Server` (ставится как служба) | `brew tap mongodb/brew && brew install mongodb-community` | https://www.mongodb.com/docs/manual/administration/install-on-linux/ или Docker |
| **Python 3.10+** + `pillow`, `python-docx` | только `tools/` (генерация отчётов и скриншотов консоли), для запуска лаб **не нужен** | https://www.python.org/downloads/ | `brew install python` | `sudo apt install python3 python3-pip` |

Минимум по ресурсам: **8 ГБ ОЗУ** (для Spark комфортнее 16), ~**3 ГБ** диска (Spark ≈ 400 МБ, пакеты R ≈ 1 ГБ, `nycflights13` и данные — небольшие).

### Пакеты R

Один раз выполни в R / RStudio:

```r
install.packages(c(
  "dplyr", "tidyr", "tibble", "readr", "readxl", "writexl", "jsonlite",
  "data.table", "ggplot2", "nycflights13",
  "DBI", "RSQLite", "mongolite", "sparklyr",
  "future", "future.apply", "randomForest", "rpart"
))
```

`parallel` и `stats` входят в базовый R. На Windows и macOS пакеты ставятся готовыми бинарниками (компиляция не нужна).

### Java и JAVA_HOME (лаба 13)

Скрипт `lab13.R` использует `JAVA_HOME`. Если переменная не задана, а на macOS есть Homebrew-JDK 17, скрипт подставит его сам. **На Windows и Linux задай `JAVA_HOME` в системе:**

```powershell
# Windows (PowerShell, затем перезапусти RStudio)
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-17.0.x-hotspot"
```

```bash
# Linux
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64      # добавь в ~/.profile
```

### Spark (лаба 13)

```r
library(sparklyr)
spark_install(version = "3.5")      # скачивает Spark 3.5.x (~400 МБ) в домашний каталог
spark_installed_versions()
```

> **Windows:** Spark требует **Microsoft Visual C++ 2010 SP1 Redistributable (x64)** — https://www.microsoft.com/en-us/download/details.aspx?id=26999 (или `choco install vcredist2010`). Без него `spark_connect()` падает с ошибкой про «Visual C++ 2010 SP1». Это подтверждено в CI. Дальше перезапусти R.
>
> **Windows, второй обязательный шаг — `winutils.exe`.** Это штатное требование Spark/sparklyr (подтверждено в CI): после `spark_install()` выполни в R
>
> ```r
> bin <- file.path(sparklyr::spark_install_find(version = "3.5")$sparkVersionDir, "tmp", "hadoop", "bin")
> dir.create(bin, recursive = TRUE, showWarnings = FALSE)
> base <- "https://github.com/steveloughran/winutils/raw/master/hadoop-3.0.0/bin/"
> for (f in c("winutils.exe", "hadoop.dll")) download.file(paste0(base, f), file.path(bin, f), mode = "wb")
> ```
>
> ⚠️ Это **сторонние бинарные файлы** (репозиторий `steveloughran/winutils`) — именно их рекомендует сам sparklyr в тексте ошибки. Если не доверяешь, собери winutils самостоятельно или запускай лабу 13 в WSL2/Linux.

### MongoDB (лаба 10)

Перед запуском лабы 10 MongoDB должен слушать `mongodb://127.0.0.1:27017`:

```bash
# macOS / Linux (своя папка данных, без службы)
mkdir -p ~/mongodb/data
mongod --dbpath ~/mongodb/data --bind_ip 127.0.0.1 --fork --logpath ~/mongodb/mongod.log
```

```powershell
# Windows: если MongoDB установлен как служба — проверь, что она запущена
Get-Service MongoDB          # Status = Running
Start-Service MongoDB
```

Альтернатива на любой ОС (нужен Docker): `docker run -d --name mongo -p 27017:27017 mongo:8`.

Без запущенного MongoDB лаба 10 завершится ошибкой `No suitable servers found … connection refused`.

---

## 3. Запуск

### Вариант А — в RStudio

1. Склонируй репозиторий (`git clone https://github.com/Kennurken/lab-bigdata.git`) и открой папку нужной лабы.
2. Установи **рабочую папку** на папку лабы (*Session → Set Working Directory → To Source File Location*) — скрипты используют относительные пути (`data/…`, `screenshots/…`).
3. Открой `labNN.R` и выполни по шагам (`Ctrl+Enter`) или целиком (`Ctrl+Shift+Enter`).

### Вариант Б — одной командой (любая ОС)

Из корня репозитория:

```bash
Rscript run_lab.R lab05-dplyr
```

Скрипт `run_lab.R` выполняет `labNN.R` внутри её папки и пишет протокол в `output.txt`. Для macOS/Linux также есть `./run_lab.sh lab05-dplyr` (zsh; в нём прописаны пути Homebrew — на других системах пользуйся `run_lab.R`).

Прогнать все лабы:

```bash
for d in lab*/; do Rscript run_lab.R "${d%/}"; done          # macOS / Linux
```

```powershell
Get-ChildItem -Directory lab* | ForEach-Object { Rscript run_lab.R $_.Name }   # Windows
```

> ⚠️ Запуск **перезаписывает** `output.txt` и картинки в `screenshots/` (числа времени в лабе 12 и случайные выборки изменятся). Если нужно сохранить текущие результаты, запускай в копии папки.

---

## 4. Особенности и ограничения по ОС

| Что | macOS / Linux | Windows |
|-----|---------------|---------|
| Лаба 12: `mclapply` (fork-параллелизм) | работает на нескольких ядрах | `mclapply` на Windows многоядерно не работает — скрипт автоматически выполняет эти шаги последовательно (`mc_lapply` в `lab12.R`). Кластеры `parLapply` и `future` (`multisession`) работают на всех ОС, поэтому сравнение методов остаётся осмысленным, но цифры «ускорения» для `mclapply` будут ≈ 1× |
| Лаба 13: Spark | JDK 17 + `JAVA_HOME` | JDK 17 + `JAVA_HOME` (+ возможно `winutils`, см. выше) |
| Лаба 10: MongoDB | `mongod` | служба `MongoDB` |
| Кодировка (кириллица/казахский в скриптах) | UTF-8 | R ≥ 4.2 на Windows использует UTF-8 по умолчанию; в RStudio: *Tools → Global Options → Code → Saving → Default text encoding = UTF-8* |
| Пути | `/` | `/` тоже работает в R; не клади проект в путь с кириллицей/пробелами, если видишь странные ошибки чтения файлов |
| Шрифт для `tools/console_png.py` | Menlo | Consolas (подхватывается автоматически) |

Лаба 9 (`flights.sqlite`) и лаба 15 (`data/project.sqlite`) создают файлы баз сами при запуске — в репозитории их нет.

---

## 5. Частые проблемы

| Симптом | Решение |
|---------|---------|
| `there is no package called 'xxx'` | Выполни `install.packages("xxx")` (список — в разделе 2). |
| `No suitable servers found … connection refused` (лаба 10) | MongoDB не запущен — раздел 2. |
| `JAVA_HOME is not set` / `Java was not found` (лаба 13) | Установи JDK 17 и задай `JAVA_HOME` — раздел 2; перезапусти RStudio. |
| `ignoring SIGPIPE signal` / `writeBin` в `spark_connect()` (лаба 13) | Spark-процесс не успел стартовать (обычно мало свободной памяти). Закрой тяжёлые программы и запусти ещё раз; при 8 ГБ ОЗУ уменьши память драйвера в `lab13.R`: `sparklyr.shell.driver-memory` → `"2G"`. |
| `Spark … not installed` (лаба 13) | `sparklyr::spark_install(version = "3.5")`. |
| `cannot open file 'data/…'` | Рабочая папка не равна папке лабы — `setwd()` или используй `run_lab.R`. |
| `'mc.cores' > 1 is not supported on Windows` | Старая версия `lab12.R` — обнови репозиторий; в актуальной версии есть обёртка `mc_lapply`. |
| Кракозябры вместо казахских букв | Сохрани/открой файл как UTF-8 (см. таблицу выше). |

---

## 6. Структура репозитория

```
lab-bigdata/
├── labNN-…/              # lab*.R, output.txt, screenshots/, ЕСЕП.md, (data/)
├── run_lab.R             # кроссплатформенный запуск лабы
├── run_lab.sh            # то же для macOS/Linux (zsh, Homebrew)
├── tools/                # Python: сборка отчётов (make_reports.py) и скриншотов консоли (console_png.py); для запуска лаб не нужны
└── .gitignore            # *.rar, *.docx, *.sqlite и артефакты запуска не коммитятся
```

> **Персональные данные.** В публичной версии ФИО автора, преподавателя и группа заменены плейсхолдерами (`<студенттің аты-жөні>` и т. д.), а в учебных данных (лабы 1, 2, 3, 9, 10) использованы вымышленные имена и группа `ИС-00-x`. Чтобы получить отчёты со своими данными, скопируй `tools/student.example.json` в `tools/student.local.json` (файл в `.gitignore`), впиши свои данные и запусти `python tools/make_reports.py`.

Файлы `ЕСЕП.docx` (Word-отчёты) и `*.rar` не хранятся в git. Отчёты (`ЕСЕП.md` и `ЕСЕП.docx`) собираются из `labNN.R`, `output.txt` и метаданных `tools/labs_meta.py` / `tools/labs_qa.py` командой `python tools/make_reports.py [папка-лабы]` (нужны `python-docx` и `pillow`: `pip install python-docx pillow`).
