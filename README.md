# BoogieCursor 项目归档（打火机/跳舞小人鼠标指针）

> 版本 v1.0 · Windows 10/11 · 仅当前用户（HKCU），无需管理员权限

## 功能

| 状态 | 效果 |
|---|---|
| 默认指针 | 斜置 -28° 跳舞小人（Boogieing 抠图 + 原图静态火苗已擦除） |
| 按住左键 | 小人头顶动态火苗（6 帧闪烁 ~8fps），热点逐帧跟随火苗尖 |
| 文本指针 | 橙黄渐变 I 型 |
| 链接指针 | 手型 |
| 系统繁忙 | 小人 ±12° 摇摆 + 光晕（6 帧） |
| 托盘图标 | 小人循环跳舞动画，右键 Exit 退出 |

## 分发（其他电脑安装）

**交付物：`BoogieCursor_v1.0.zip`**（本目录 / 桌面各一份）

目标机器解压后右键 `install.ps1` →「使用 PowerShell 运行」即可：
1. 复制文件到 `%LOCALAPPDATA%\BoogieCursor`（稳定路径，与解压位置无关）
2. 写注册表 `HKCU\Control Panel\Cursors` + `SystemParametersInfo(SPI_SETCURSORS)` 应用
3. 启动 `FlameClick.ps1` 常驻 + 启动文件夹开机自启

卸载：运行 `uninstall.ps1`（恢复 aero 默认指针、清理全部痕迹）。

## 开发文件（本目录）

| 文件 | 用途 |
|---|---|
| `make-cursors.ps1` | 生成全部光标；优先用 `assets\Boogieing_processed.png`（已抠图+去火苗的可移植素材），无则从 `D:\我的下载\Boogieing.png` 原图处理并导出素材 |
| `apply-cursors.ps1` | 开发环境应用方案（写注册表 + 重载） |
| `FlameClick.ps1` | 常驻点击火苗效果（生产版，被分发包引用） |
| `install-startup.ps1` / `restore-default.ps1` | 开发环境快速启停 |
| `Cursors\` | 生成的 .cur/.ani/托盘帧 |
| `assets\` | 可移植处理素材 |
| `BoogieCursor_Package\` | 分发包源目录 |

## 技术要点

- **光标二进制手工生成**：GDI+ 256px 抗锯齿绘制 → 逐级对半降采样至 32px → 手写 `.cur`（ICONDIR + BITMAPINFOHEADER + BGRA 自下而上 + AND 掩码）与 `.ani`（RIFF/ACON + anih + LIST fram）
- **原图火苗擦除**：暖色特征识别（R-B>70）+ 2 轮光晕膨胀 + 深色描边碎片清理，仅作用于顶部区域
- **点击火苗**：`WH_MOUSE_LL` 低级钩子监听 0x201/0x202 → `SetSystemCursor` 热切换；恢复时从注册表路径 `LoadImage`（确定性，不会误存火苗）；250ms `GetAsyncKeyState` 安全定时器防粘滞
- **防跳变**：倾斜轴固定在头顶基准点，火苗闪烁时身体不动；按压/松开两态身体坐标完全一致

## 自定义参数（make-cursors.ps1）

- `$flick`：火苗帧参数（h 高度 / lean 倾斜 / w 宽度，256 空间）
- `$TILT`：倾斜角（默认 -28°）
- `DrawImage($big, 54, 46, 148, 190)`：小人尺寸/位置
- `$angles` / `$bobs`：忙碌动画摇摆/弹跳

重新生成后运行 `apply-cursors.ps1` 并重启常驻即可。

## 已知限制

- 非提升进程的全局钩子对少数 UIPI 隔离场景可能收不到事件（安全定时器兜底）
- 修改 `.cur` 前需先停常驻（托盘 Exit 或结束进程），避免文件占用
