# MemoryReader Class - AutoHotkey v2

## Overview
The `MemoryReader` class is designed to facilitate reading memory from running programs on Windows. This class provides developers with an efficient way to access data from the memory of running processes, which is useful for applications such as real-time monitoring, debugging, game stats reading, and more.

The class has two main methods:
- **`getFinalAddress(processName, baseOffset, offsets)`**: Calculates and retrieves the final memory address starting from a base address and using a list of pointers.
- **`readMemory(processName, address, size)`**: Reads the content of a specific memory address after it has been determined, either through a fixed address or by using `getFinalAddress`.

Please note that reading memory requires appropriate permissions and should be used responsibly to avoid unintended consequences, such as application crashes.

## Installation and Setup
To use the `MemoryReader` class, you will need:
- **AutoHotkey v2.0** installed on your system.
- Basic knowledge of memory structures in Windows processes.

Make sure you run the script with elevated privileges (administrator mode) to gain access to the memory of certain processes.

## Methods Description

### `getFinalAddress(processName, baseOffset, offsets)`
This method calculates the final memory address by navigating through a chain of pointers starting from a base address.

- **`processName`**: The name of the process to connect to, such as `notepad.exe`. This helps identify the target application.
- **`baseOffset`**: The base address to start with (e.g., `0x0537A1CC`). This value is typically static for a given process.
- **`offsets`**: A list of pointers/offsets used to navigate through memory (e.g., `[0xF0, 0x40, 0x78, 0x48, 0x54, 0xCC, 0x50]`). These offsets are often obtained using tools like Cheat Engine.

This method is especially helpful for scenarios where memory addresses change each time a program is run, allowing you to consistently locate dynamic values.

**Example Usage**:
```ahk
reader := MemoryReader()
process := "notepad.exe"
baseOffset := 0x0537A1CC
offsets := [0xF0, 0x40, 0x78, 0x48, 0x54, 0xCC, 0x50]
finalAddress := reader.getFinalAddress(process, baseOffset, offsets)
if (finalAddress)
{
    MsgBox("Final Address: " . Format("{:#x}", finalAddress))
}
else
{
    MsgBox("Failed to retrieve the final address.")
}
```

### `readMemory(processName, address, size := 4)`
This method reads the value stored at a given memory address.

- **`processName`**: The name of the process to connect to, such as `notepad.exe`.
- **`address`**: The specific memory address to read (e.g., `0x0537A1CC`). You can use an address obtained from `getFinalAddress`.
- **`size`**: The number of bytes to read (default is 4 bytes).

This function is useful for accessing real-time data from a running process, which could include game statistics, configuration values, or other internal data.

**Example Usage**:
```ahk
reader := MemoryReader()
process := "notepad.exe"
address := 0x0537A1CC ; This could also be the result of getFinalAddress()
value := reader.readMemory(process, address)
if (value)
{
    MsgBox("Value at Address: " . value)
}
else
{
    MsgBox("Failed to read memory.")
}
```

## Complete Example
Here is an example of using both methods to retrieve a dynamic address and then read the value stored at that address:

```ahk
reader := MemoryReader()
process := "notepad.exe"
baseOffset := 0x0537A1CC
offsets := [0xF0, 0x40, 0x78]

finalAddress := reader.getFinalAddress(process, baseOffset, offsets)
if (finalAddress)
{
    value := reader.readMemory(process, finalAddress)
    if (value)
    {
        MsgBox("Value at Final Address: " . value)
    }
    else
    {
        MsgBox("Failed to read memory at the calculated address.")
    }
}
else
{
    MsgBox("Failed to retrieve the final address.")
}
```

## Dependencies
- **AutoHotkey v2.0**: Make sure you have the latest version installed.
- **Administrator Privileges**: Required for accessing memory in certain processes.

## Safety and Ethics Notice
Reading or modifying the memory of a program can lead to unintended consequences, such as crashes or data corruption. Always test in a safe environment and avoid using these techniques on applications without permission. Unauthorized memory manipulation may violate software terms of service or local laws, so proceed responsibly.

## FAQ
**Q: Why does `getFinalAddress` return 0?**
- This could be because the target process is not running, or the provided offsets are incorrect.

**Q: What permissions are needed to read memory?**
- You need to run the script as an administrator to access the memory of most processes.

**Q: How do I find the base address and offsets?**
- Use a tool like **Cheat Engine** to inspect the memory of the target application and find the necessary addresses and offsets.

## Troubleshooting Tips
- Ensure the process is running before attempting to read memory.
- Make sure the provided process name matches exactly (e.g., `notepad.exe`).
- Use the correct offsets; incorrect values will lead to failure in finding the desired address.

## License
This script is released under the MIT License. You are free to use, modify, and distribute it, but use it at your own risk.

## Contributions
Contributions are welcome! If you have suggestions, improvements, or bug reports, feel free to open an issue or submit a pull request.

