# BoogieCursor （打火机鼠标指针）

> 版本 v1.0 · Windows 10/11

## 功能

| 状态 | 效果 |
|---|---|
| 默认指针 | 斜置 -28° 跳舞小人 |
| 按住左键 | 小人头顶动态火苗（6 帧闪烁 ~8fps），热点逐帧跟随火苗尖 |
| 文本指针 | 橙黄渐变 I 型 |
| 链接指针 | 手型 |
| 系统繁忙 | 小人 ±12° 摇摆 + 光晕（6 帧） |
| 托盘图标 | 小人循环跳舞动画，右键 Exit 退出 |

## 其他电脑安装
目标机器解压后右键 `install.ps1` →「使用 PowerShell 运行」即可：
1. 复制文件到 `%LOCALAPPDATA%\BoogieCursor`（稳定路径，与解压位置无关）
2. 写注册表 `HKCU\Control Panel\Cursors` + `SystemParametersInfo(SPI_SETCURSORS)` 应用
3. 启动 `FlameClick.ps1` 常驻 + 启动文件夹开机自启

卸载：运行 `uninstall.ps1`（恢复 aero 默认指针、清理全部痕迹）。

## 开发文件

| 文件 | 用途 |
|---|---|
| `make-cursors.ps1` | 生成全部光标 |
| `apply-cursors.ps1` | 开发环境应用方案（写注册表 + 重载） |
| `FlameClick.ps1` | 常驻点击火苗效果 |
| `install-startup.ps1` / `restore-default.ps1` | 开发环境快速启停 |
| `Cursors\` | 生成的 .cur/.ani/托盘帧 |
| `assets\` | 可移植处理素材 |
| `BoogieCursor_Package\` | 分发包源目录 |
