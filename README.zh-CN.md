# WhiteSur Light/Dark Toggle

[English](README.md) | 简体中文

一个 GNOME Shell 快速设置（Quick Settings）开关，一键在 WhiteSur 的浅色和深色主题之间切换。

脚本会同步切换 Shell 主题、GTK 主题、图标主题、窗口装饰、系统深浅色偏好、圆角窗口边框颜色，以及 VS Code 的配色，并把最显眼的 Shell 主题放在最前面执行，点击后顶栏几乎立刻变色。

在 GNOME Shell 50.1（Ubuntu）上测试通过。

## 组成

```
whitesur-light-dark-toggle/
├── bin/
│   ├── theme-dark.sh             # 切到深色
│   ├── theme-light.sh            # 切到浅色
│   ├── gtk4-merge-css            # 生成明暗合并的 GTK4 gtk.css
│   ├── rounded-corners-borders   # 同步圆角窗口边框颜色
│   └── vscode-theme              # 同步 VS Code colorTheme
├── config/
│   └── custom-command-toggle.dconf   # 快速切换按钮的配置参考
├── extras/
│   └── rounded-corners-personal.dconf  # 个人应用圆角配置（不自动安装）
├── docs/
│   └── troubleshooting.md        # 切换卡顿的原因与优化记录
├── install.sh
├── uninstall.sh
└── LICENSE
```

## 依赖

必需：

- GNOME Shell 45+（在 50.1 上测试）
- [WhiteSur GTK theme](https://github.com/vinceliuice/WhiteSur-gtk-theme)，蓝色变体：
  `~/.themes/WhiteSur-Light-blue`、`~/.themes/WhiteSur-Dark-blue`
- [WhiteSur icon theme](https://github.com/vinceliuice/WhiteSur-icon-theme)：`WhiteSur`
- GNOME 扩展 [user-theme](https://gitlab.gnome.org/GNOME/gnome-shell-extensions)（用来切换 Shell 主题）
- GNOME 扩展 [Custom Command Toggle](https://github.com/StorageB/custom-command-toggle)（提供快速设置按钮）

可选：

- GNOME 扩展 [rounded-window-corners-reborn](https://github.com/flexagoon/rounded-window-corners)
  （没有它时 `rounded-corners-borders` 会直接报错退出，其它步骤不受影响）
- VS Code / VSCodium（`vscode-theme` 会自动查找常见配置路径）
- `python3-gi`（`rounded-corners-borders` 和 `vscode-theme` 需要）

## 安装

```bash
git clone https://github.com/zzxxchen/whitesur-light-dark-toggle.git
cd whitesur-light-dark-toggle
./install.sh
```

安装脚本会：

1. 把 `bin/` 下的脚本软链到 `~/.config/bin/`（已有同名文件会先备份为 `*.bak-<时间戳>`）；
2. 只配置快速切换按钮 1（名称、图标、深/浅两条命令），不会动你其它的按钮；
3. 检查主题、图标和扩展是否齐全，缺失时给出提示。

常用参数：

```bash
./install.sh --dry-run   # 只打印将要做的事
./install.sh --copy      # 复制脚本而不是软链（之后更新仓库需重新运行）
```

安装后还需要手动完成：

1. 按官方 README 安装 WhiteSur GTK 主题（选择蓝色、Light/Dark 变体）、WhiteSur 图标主题和 Shell 主题；
2. 在「扩展」中启用 `user-theme`、`Custom Command Toggle`，以及可选的 `rounded-window-corners`；
3. 打开快速设置，点击 “WhiteSur Dark” 开关测试。

## 工作原理

`theme-dark.sh` / `theme-light.sh` 依次执行：

1. `gtk4-merge-css`：确保 `~/.config/gtk-4.0/gtk.css` 是“明暗合并”版本
   （`@media (prefers-color-scheme: ...)` 两个分支），这样切换时不需要替换这个文件，
   libadwaita 应用会自动跟随 `color-scheme`。
2. `dconf write .../user-theme/name`：切换 Shell 主题。**放在最前面**是有意的：
   这一步最显眼，先写它，顶栏/菜单/概览会立刻变色；后面的 `color-scheme` 等设置
   引起的重绘在后台继续。
3. `gsettings set ... color-scheme`：系统深浅色偏好，libadwaita / GTK4 应用据此换色。
4. 切换 `gtk-theme`、`icon-theme`、`wm.preferences theme`。
5. `rounded-corners-borders light|dark`：只改圆角窗口边框颜色，保留圆角半径等设置。
   `Termius`、`steam`、`eudic` 等应用可以固定颜色，见脚本里的 `PINNED_COLORS`。
6. `vscode-theme light|dark`：只替换 `workbench.colorTheme`，保留 `settings.json` 的其它内容。

## 自定义

- 不使用蓝色变体：修改两个主题脚本里的 `WhiteSur-Light-blue` / `WhiteSur-Dark-blue`。
- 图标主题不同：修改脚本里的 `icon-theme`。
- 圆角边框颜色：修改 `bin/rounded-corners-borders` 顶部的 `DEFAULT_COLORS` 和 `PINNED_COLORS`。
- 增加固定颜色的应用：在 `PINNED_COLORS` 里按 `应用 ID: 颜色` 添加。
- VS Code 配置路径：修改 `bin/vscode-theme` 里的 `SETTINGS_CANDIDATES`。

## 关于切换延迟

如果你觉得切换要等两三秒，见 [docs/troubleshooting.md](docs/troubleshooting.md)：主要原因是
`blur-my-shell` 在 `color-scheme` 变化时同步重建模糊效果，会阻塞 GNOME Shell 主循环。
本仓库默认采用的“Shell 主题优先”写法已经把可见延迟降到 0.1 秒级。

## 卸载

```bash
./uninstall.sh              # 只删除本仓库软链进去的脚本
./uninstall.sh --reset-keys # 同时重置快速切换按钮 1 的配置
```

主题、图标和扩展不在此仓库的安装范围内，不会被删除。

## License

[MIT](LICENSE)
