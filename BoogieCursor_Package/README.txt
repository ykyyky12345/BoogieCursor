BoogieCursor 打火机跳舞小人鼠标指针包 v1.0
================================================

【效果】
- 默认指针：斜置 28° 的跳舞小人（无火苗）
- 按住鼠标左键：小人头顶燃起动态火苗（6 帧闪烁动画），松开熄灭
- 文本指针：橙黄色渐变 I 型
- 链接指针：手型
- 系统繁忙：小人 ±12° 摇摆跳舞 + 橙色光晕
- 托盘图标：小人循环跳舞动画（右键 Exit 退出常驻）

【安装】（Windows 10/11）
1. 解压本文件夹到任意位置
2. 右键 install.ps1 -> 使用 PowerShell 运行
   （或在 PowerShell 中执行: powershell -ExecutionPolicy Bypass -File install.ps1）
3. 完成！按住鼠标左键即可看到火苗

【卸载】
右键 uninstall.ps1 -> 使用 PowerShell 运行
（恢复 Windows 默认指针、停止常驻、移除开机启动）

【原理】
- install.ps1 将文件复制到 %LOCALAPPDATA%\BoogieCursor（稳定路径，与解压位置无关）
- 指针方案写入注册表 HKCU\Control Panel\Cursors 并调用 SystemParametersInfo 重载
- FlameClick.ps1 通过 WH_MOUSE_LL 低级鼠标钩子监听左键按下/抬起，
  调用 SetSystemCursor 热切换火苗动画光标；250ms 安全定时器防止火苗粘滞
- 开机自启：启动文件夹快捷方式

【自定义】（进阶）
tools\make-cursors.ps1 可重新生成全部指针文件：
- 火苗大小/闪烁：$flick 参数表（h=高度 lean=倾斜 w=宽度，256 画布空间）
- 倾斜角度：$TILT（默认 -28）
- 小人大小：DrawImage($big, 54, 46, 148, 190) 的宽高
生成后把 tools\Cursors 下的文件复制到 Cursors\，重新运行 install.ps1

【注意】
- 仅当前用户生效（HKCU），无需管理员权限
- 常驻脚本占用极低（钩子 + 定时器）
- 若杀毒软件拦截 PowerShell 钩子，请添加信任
