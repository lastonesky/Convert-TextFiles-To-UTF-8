# Convert-TextFiles-To-UTF-8

批量把文本文件编码统一为 UTF-8 BOM。

支持两种脚本：
- Windows / PowerShell: `convert_textfiles_to_utf8.ps1`
- Linux / Bash: `convert_textfiles_to_utf8_linux.sh`

处理规则：
- 已是 UTF-8 BOM：跳过
- UTF-8 无 BOM：补 BOM（normalize）
- 非 UTF-8（如 ANSI/GBK）：转换为 UTF-8 BOM

默认处理文件模式：
- `*.cs,*.vb,*.aspx`

## 为什么统一到 UTF-8 BOM

- 跨编辑器和旧工具链更稳定，减少中文乱码风险
- 团队编码格式一致，降低 diff 噪音和合并冲突
- 对无 BOM 的 UTF-8 文件做 normalize，避免同仓库混用多种文本编码
- 若你的链路明确要求 UTF-8 无 BOM，可按需改写脚本输出策略

## PowerShell 用法

```powershell
.\convert_textfiles_to_utf8.ps1 -folder . 
.\convert_textfiles_to_utf8.ps1 -folder d:\path\to\your\project\App_Code
.\convert_textfiles_to_utf8.ps1 -folder . -patterns *.cs,*.vb,*.aspx
```

## Linux 用法

```bash
chmod +x ./convert_textfiles_to_utf8_linux.sh
./convert_textfiles_to_utf8_linux.sh -folder .
./convert_textfiles_to_utf8_linux.sh -folder /path/to/your/project/App_Code
./convert_textfiles_to_utf8_linux.sh -folder . -patterns "*.cs,*.vb,*.aspx"
```
