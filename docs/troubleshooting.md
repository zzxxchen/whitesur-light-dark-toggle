# 切换延迟排查记录

在 GNOME Shell 50.1 上，点击快速切换按钮后要等 3–4 秒才看到变化。记录一下原因和可选优化，
方便以后换机器时参考。

## 结论

- `theme-dark.sh` / `theme-light.sh` 本身只需约 **0.3 秒**，慢的不是脚本。
- 把 `user-theme/name` 写在最后时，Shell 要等 **约 2.5 秒**才打印
  `loading user theme`，因为主循环被前面的 `color-scheme` 变更堵住了。
- 用 D-Bus 调用探测 Shell 主循环响应时间，单次 `color-scheme` 变更有约：

  | 条件 | 主循环最长阻塞 |
  | --- | --- |
  | 全部扩展启用 | 约 2.2–2.6 s |
  | 禁用 `blur-my-shell` | 约 0.5–0.8 s |
  | 禁用 `kiwi` | 约 2.3–2.5 s（无改善） |
  | `gtk-theme` 单独变更 | 约 0.02–0.4 s |
  | `icon-theme` 单独变更 | 约 0.01–0.6 s |

- 在 `blur-my-shell` 内部，`dash-to-dock` 大约贡献 0.85 s，`overview` 约 0.4 s，
  其余分散在多个组件；`panel` 基本无关。

## 已采用的方案（方案 C）

只调整 `theme-dark.sh` / `theme-light.sh` 的顺序：把 `user-theme/name` 的 `dconf write`
放到最前面。

实测（切浅色）：

```
脚本开始                        22:33:49.279
Shell 加载新主题                22:33:49.297   (+18 ms)
脚本结束                        22:33:49.551
```

顶栏/菜单/概览几乎立刻变色，总耗时不变。

## 可选的进一步优化

### 方案 A：给 blur-my-shell 的主题回调去抖

`blur-my-shell/conveniences/style.js` 的 `connect_system_style_changes()` 会同时监听
`changed::color-scheme`、`changed::gtk-theme`、`St.Settings notify::color-scheme` 和
`ThemeContext 'changed'`，一次切换会触发多轮回调。而且当前所有组件的
`pipeline-auto-mode` 都是 `false`，回调里的重算基本是多余的。

可以加一个合并空闲回调（例如 100–200 ms 去抖），并在 auto mode 关闭时直接跳过。
预期能把主循环阻塞降到 0.15 s 以内。这会修改扩展文件，升级扩展时可能被覆盖。

### 方案 B：减少模糊目标

关闭 `blur-my-shell` 中 `overview` 和 `dash-to-dock` 的模糊，可省约 0.8–1 s，
但会失去这两处的模糊效果。

## 复现测量

脚本总耗时：

```bash
/usr/bin/time -f '%e s' ~/.config/bin/theme-dark.sh
```

观察 Shell 何时真正加载主题：

```bash
logger -t MARK "start $(date +%s.%N)"
~/.config/bin/theme-dark.sh >/dev/null 2>&1
logger -t MARK "done $(date +%s.%N)"
sleep 4
journalctl --user -b -o short-precise --since "-8 s" | grep -E "MARK|loading user theme"
```

探测主循环阻塞（需要 Shell 的 D-Bus 接口）：

```bash
gdbus call --session --dest org.gnome.Shell \
  --object-path /org/gnome/Shell \
  --method org.freedesktop.DBus.Properties.GetAll org.gnome.Shell
```

在变更 `gsettings` 的同时循环调用它，记录往返时间的峰值即可。

> 注意：频繁开关扩展、反复触发主题重绘可能让某个扩展进入异常状态。排查时最好单独进行，
> 结束后把主题和扩展状态恢复一致（`color-scheme` 与 `gtk-theme`、`icon-theme` 深浅要匹配）。
