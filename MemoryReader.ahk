#Requires AutoHotkey v2.0

class MemoryReader {
    GetFinalAddress(processName, baseOffset, offsets) {
        pid := WinGetPID("ahk_exe " . processName)
        if (!pid) {
            MsgBox("Processo não encontrado.")
            return 0
        }

        ; Open the process with full access (PROCESS_ALL_ACCESS)
        hProcess := DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", false, "UInt", pid, "Ptr")
        if (!hProcess) {
            MsgBox("Falha ao abrir o processo com acesso total.")
            return 0
        }

        snapFlags := 0x00000008 | 0x00000010
        hSnapshot := DllCall("CreateToolhelp32Snapshot", "UInt", snapFlags, "UInt", pid, "Ptr")
        if (hSnapshot == -1) {
            MsgBox("Falha ao criar snapshot.")
            DllCall("CloseHandle", "Ptr", hProcess)
            return 0
        }

        ; Adjustments for compatibility between 32 and 64 bits
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
            if (szModule == processName) {
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
            value := this.ReadPointer(hProcess, currentAddress)
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

    ReadPointer(hProcess, address) {
        bufferx := Buffer(4)  ; Ensure reading 32 bits
        result := DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", address, "Ptr", bufferx, "UInt", 4, "Ptr", 0)
        if (!result) {
            return 0
        }
        return NumGet(bufferx, 0, "UInt")
    }

    ReadMemory(processName, address, tamanho := 4) {
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

        bufferx := Buffer(tamanho)
        result := DllCall("ReadProcessMemory", "Ptr", hProcess, "Ptr", address, "Ptr", bufferx, "Ptr", tamanho, "Ptr", 0)

        if (!result) {
            MsgBox("Falha ao ler a memória no endereço " . Format("{:#x}", address))
            DllCall("CloseHandle", "Ptr", hProcess)
            return
        }

        valor := NumGet(bufferx, 0, tamanho == 8 ? "Int64" : "Int")
        DllCall("CloseHandle", "Ptr", hProcess)

        return valor
    }
}