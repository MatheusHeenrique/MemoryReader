#Requires AutoHotkey v2.0

class MemoryReader {
    getFinalAddress(processName, baseOffset, offsets, moduleName := "") {
        pid := WinGetPID("ahk_exe " . processName)
        if (!pid) {
            MsgBox("Processo não encontrado.")
            return 0
        }

        ; Abrir o processo com acesso total (PROCESS_ALL_ACCESS)
        hProcess := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", false, "UInt", pid, "Ptr")
        if (!hProcess) {
            MsgBox("Falha ao abrir o processo com acesso total.")
            return 0
        }

        snapFlags := 0x00000008 | 0x00000010  ; TH32CS_SNAPMODULE | TH32CS_SNAPMODULE32
        hSnapshot := DllCall("CreateToolhelp32Snapshot", "UInt", snapFlags, "UInt", pid, "Ptr")
        if (hSnapshot == -1) {
            MsgBox("Falha ao criar snapshot.")
            DllCall("CloseHandle", "Ptr", hProcess)
            return 0
        }

        ; Ajustes para compatibilidade entre 32 e 64 bits
        if (A_PtrSize == 8) {
            moduleEntrySize := 1080
            offset_modBaseAddr := 24
            offset_szModule := 48
        } else {
            moduleEntrySize := 1064
            offset_modBaseAddr := 20
            offset_szModule := 32
        }

        moduleEntry := Buffer(moduleEntrySize)
        NumPut("UInt", moduleEntrySize, moduleEntry)

        result := DllCall("Module32First", "Ptr", hSnapshot, "Ptr", moduleEntry, "Int")
        found := false

        while (result) {
            szModule := StrGet(moduleEntry.Ptr + offset_szModule, "UTF-8")
            ; Se moduleName não for fornecido, usar processName
            targetModule := moduleName != "" ? moduleName : processName

            if (szModule == targetModule) {
                found := true
                modBaseAddr := NumGet(moduleEntry, offset_modBaseAddr, "Ptr")
                break
            }
            result := DllCall("Module32Next", "Ptr", hSnapshot, "Ptr", moduleEntry, "Int")
        }

        DllCall("CloseHandle", "Ptr", hSnapshot)

        if (!found) {
            MsgBox("Módulo não encontrado.")
            DllCall("CloseHandle", "Ptr", hProcess)
            return 0
        }

        initialAddress := modBaseAddr + baseOffset
        currentAddress := initialAddress

        for offset in offsets {
            value := this.readPointer(hProcess, currentAddress)
            if (value == 0 || value > 0x7FFFFFFF) {
                MsgBox("Falha ao ler memória no endereço " . Format("{:#x}", currentAddress))
                DllCall("CloseHandle", "Ptr", hProcess)
                return 0
            }
            currentAddress := value + offset
        }

        DllCall("CloseHandle", "Ptr", hProcess)
        return currentAddress
    }

    readPointer(hProcess, address) {
        bufferx := Buffer(4)  ; Garante a leitura de 32 bits
        result := DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", address, "Ptr", bufferx, "UInt", 4, "Ptr", 0)
        if (!result) {
            return 0
        }
        return NumGet(bufferx, 0, "UInt")
    }

    /*
        Parâmetros de readMemory:
        - processName: Nome do processo (ex.: "exemplo.exe")
        - address: Endereço de memória a ler
        - size: Quantidade de bytes a serem lidos (padrão = 4)
        - dataType: Tipo de dado a ler ("int" ou "string"; padrão = "int")
          Se "int", usará NumGet (4 ou 8 bytes, dependendo de size).
          Se "string", usará StrGet no buffer lido.
    */
    readMemory(processName, address, size := 4, dataType := "int") {
        pid := WinGetPID("ahk_exe " . processName)
        if (!pid) {
            MsgBox("Processo não encontrado.")
            return
        }

        hProcess := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", false, "UInt", pid, "Ptr")
        if (!hProcess) {
            MsgBox("Falha ao abrir o processo com acesso total.")
            return
        }

        bufferx := Buffer(size)
        result := DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", address, "Ptr", bufferx, "Ptr", size, "Ptr", 0)

        if (!result) {
            MsgBox("Falha ao ler a memória no endereço " . Format("{:#x}", address))
            DllCall("CloseHandle", "Ptr", hProcess)
            return
        }

        if (dataType = "string") {
            ; Interpreta o conteúdo do buffer como string (UTF-8 ou outro encoding conforme necessidade)
            valor := StrGet(bufferx, "UTF-8")
        } else {
            ; Mantém funcionamento original para valores numéricos
            if (size = 8) {
                valor := NumGet(bufferx, 0, "Int64")
            } else {
                valor := NumGet(bufferx, 0, "Int")
            }
        }

        DllCall("CloseHandle", "Ptr", hProcess)
        return valor
    }
}
