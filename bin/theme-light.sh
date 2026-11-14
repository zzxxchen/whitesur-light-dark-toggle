#!/usr/bin/env bash

# 确保 gtk-4.0/gtk.css 是明暗合并样式（切换时不再替换它）
"$HOME/.config/bin/gtk4-merge-css"

# 先切换 Shell 主题：这一步最显眼，优先写它，让顶栏/菜单/概览先变色，
# 后面的重活（color-scheme 等引起的重绘）再在后台完成。
dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-Light-blue'"

gsettings set org.gnome.desktop.interface color-scheme prefer-light
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Light-blue"
gsettings set org.gnome.desktop.wm.preferences theme 'WhiteSur-Light-blue'

"$HOME/.config/bin/rounded-corners-borders" light
"$HOME/.config/bin/vscode-theme" light
