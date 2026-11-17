# Typora

本仓库将 AUR 的 [`typora-free-with-plugin`](https://aur.archlinux.org/packages/typora-free-with-plugin) 迁移为 Nix 软件包。对外统一使用 `typora`：包属性为 `typora`，命令为 `typora`，桌面入口为 `typora.desktop`，菜单显示名称为 **Typora**。

软件内容仍是免费 beta **Typora 0.11.18**，搭配 **obgnail/typora_plugin 1.19.16**。插件版本与编辑器版本独立；Nix derivation 的完整版本是 `0.11.18-plugin-1.19.16`。

## 来源与许可

固定来源集中在 [`pkgs/typora/sources.nix`](../pkgs/typora/sources.nix)：

- Typora：[wyf9661/typora-free 的 v0.11.18 发布](https://github.com/wyf9661/typora-free/releases/tag/v0.11.18)，按架构下载 amd64 或 arm64 Debian 包。
- 插件：[obgnail/typora_plugin 的 1.19.16 发布](https://github.com/obgnail/typora_plugin/releases/tag/1.19.16)，下载 `typora-plugin@v1.19.16.zip`。
- AUR 迁移基线是 `typora-free-with-plugin 1.19.16-1`，其中 AUR 的 `pkgver` 对应插件版本。

AUR 的 PKGBUILD 和 `.install` 仅用于核对迁移行为。本包构建直接使用上述固定 GitHub release URL 和 SHA-256，不在构建时请求 AUR、执行 PKGBUILD 或安装 pacman 钩子。

AUR 基线提供的 SHA-256 校验值如下，表达式中使用等价的 SRI 格式：

```text
Typora amd64  a202935a754c4b7344cc947db143e12885e4a716ca5f70f607f0318c346bb6c6
Typora arm64  12ad46732c4da7d9414701c584fee942baf83b89165563f18ba03d859eb59ad8
插件 zip      6cb2d9d1d1720a1c78daa9e93d34f0c9347820d9049b076e7a548be5a728efe3
```

Typora 是专有二进制软件，免费 beta 不等于自由软件；包的 `meta.license` 为 `lib.licenses.unfree`。安装时需要由调用方允许 unfree。插件项目采用 MIT 许可，随插件提供的第三方资源分别遵守其上游许可。Typora 的上游版权文件安装在 `$out/share/licenses/typora/typora-copyright`。

## 构建与运行

在本仓库目录执行：

```sh
nix build .#typora
./result/bin/typora ./notes.md
```

只构建、不留下 `result` 链接：

```sh
nix build --no-link .#typora
```

直接运行或加入用户 profile：

```sh
nix run .#typora -- ./notes.md
nix profile install .#typora
typora ./notes.md
```

需要启用 Nix 的 `nix-command`、`flakes` 功能；也可以在每条命令的 `nix` 后添加 `--extra-experimental-features 'nix-command flakes'`。本仓库的 Flake 固定使用 `github:NixOS/nixpkgs/nixos-26.05`，其 `packages`/`checks` 导入启用了 `allowUnfree`；直接使用包函数时仍尊重调用方的许可策略。

Flake 沿用仓库现有的 `x86_64-linux` 输出。包表达式本身有 `x86_64-linux`、`aarch64-linux` 两个源记录，可由相应架构的 nixpkgs 通过 `callPackage` 导入；这不表示已经验证过 arm64 的构建和图形运行。

## NixOS、Home Manager 与 overlay

以下 `/path/to/nur-packages` 均需替换为本仓库的实际绝对路径。

NixOS module 可以直接导入软件包：

```nix
{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "typora";
  environment.systemPackages = [
    (pkgs.callPackage /path/to/nur-packages/pkgs/typora { })
  ];
}
```

也可使用仓库现有 overlay：

```nix
{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "typora";
  nixpkgs.overlays = [ (import /path/to/nur-packages/overlay.nix) ];
  environment.systemPackages = [ pkgs.typora ];
}
```

nixpkgs 自带同名的正式版 `typora`。应用本仓库 overlay 后，`pkgs.typora` 会被本包替换；未应用 overlay 时，直接引用 `pkgs.typora` 会得到 nixpkgs 的版本。两者的命令、图标和桌面文件同名，不应同时安装到同一个 profile。

Home Manager 可使用同一 overlay，并把包放入 `home.packages`：

```nix
{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "typora";
  nixpkgs.overlays = [ (import /path/to/nur-packages/overlay.nix) ];
  home.packages = [ pkgs.typora ];
}
```

如果 Home Manager 使用 `useGlobalPkgs = true`，应在 NixOS 的 nixpkgs 配置中设置 overlay 和 unfree 策略，再在 Home Manager 中添加 `home.packages = [ pkgs.typora ];`。

现有 Flake 的消费者可以引用 `inputs.nur-packages.overlays.default`。本地开发时可将该输入设为 `path:/path/to/nur-packages`；已发布仓库的 URL 由使用者自行指定。`inputs.nur-packages.inputs.nixpkgs.follows = "nixpkgs"` 可使其跟随系统的 nixpkgs 输入，兼容性需对新的调用方 nixpkgs 重新验证。

不使用 overlay 的传统导入方式：

```nix
let
  repo = import /path/to/nur-packages { inherit pkgs; };
in
repo.typora
```

根 `default.nix` 的参数是 `{ pkgs }`，不会自行创建另一份 nixpkgs，也不会更改调用方的 unfree 策略。

## 软件包接口

实现位于 [`pkgs/typora/default.nix`](../pkgs/typora/default.nix)，普通构建依赖由 `pkgs.callPackage` 注入。以下四个参数用于定制：

- `sources`：属性集，默认 `import ./sources.nix`。包含字符串 `typoraVersion`、`pluginVersion`，按 Nix system 索引的 `typora` 属性集，以及 `plugin` 属性集；每个下载记录包含字符串 `url`、`hash`。
- `typoraSrc`：可转成源路径的本地路径或 derivation，默认按 `stdenv.hostPlatform.system` 从 `sources.typora` 获取固定 `.deb`。覆盖后仍必须提供与该架构匹配的 Debian 包及预期的 Typora 文件布局。
- `pluginSrc`：本地路径或 derivation，默认获取 `sources.plugin` 的固定 ZIP。归档必须含有 `plugin/index.js` 及相应配置；传入 GitHub 自动生成的仓库源码 ZIP 不能直接替代这种发布包布局。
- `extraFlags`：字符串列表，默认 `[]`。各元素经 shell 参数转义后，放在用户传入参数之前。每个元素是一个完整参数；含空格的单个参数不会被拆开。

直接覆盖示例：

```nix
pkgs.callPackage /path/to/nur-packages/pkgs/typora {
  typoraSrc = /srv/dist/typora_0.11.18_amd64.deb;
  pluginSrc = /srv/dist/typora-plugin.zip;
  extraFlags = [ "--disable-gpu" ];
}
```

已应用本仓库 overlay 时，可写：

```nix
pkgs.typora.override {
  extraFlags = [ "--disable-gpu" ];
}
```

使用 `overrideAttrs` 可以扩展常规构建阶段，但建议用 `override` 修改这些专用参数。例如覆盖 `typoraSrc` 比单独覆盖 derivation 的 `src` 更能表达来源选择；修改版本时应同时更新 `sources`，避免包元数据仍显示旧版本。

`passthru` 公开以下属性，Nixpkgs 的 derivation 也把它们暴露为直接属性：

- `typora.typoraVersion`：编辑器版本。
- `typora.pluginVersion`：插件版本。
- `typora.sources`：固定来源元数据。
- `typora.tests.layout`：检查安装路径、桌面入口、图标、插件注入与 updater 默认配置的 derivation。
- `typora.tests.runtime`：利用 Electron 的 Node 模式检查实际启动器的 derivation，覆盖参数边界、配置初始化、保留原配置、软链接及错误路径。
- `typora.tests.gui`：在虚拟 X 显示中创建实际窗口，并检查插件加载结果；要求启用插件数大于零、错误数为零。测试显式传入 `--no-sandbox --disable-gpu`，这些是测试环境参数，不是包默认参数。检查显式提供 DejaVu 字体和临时 fontconfig 配置，不依赖宿主机的字体安装。

本仓库 Flake 导出 `packages.x86_64-linux.typora`，`nix run .#typora` 根据 `meta.mainProgram = "typora"` 选择命令，不需要额外的 `apps` 输出。

## 插件设置与 AUR 配置迁移

用户配置文件为：

```text
$HOME/.config/typora_plugin/settings.user.toml
```

这是固定版本插件原生支持的路径，不随 `XDG_CONFIG_HOME` 改变。启动器首次启动时创建空文件，权限为 `0600`。已有文件不会被覆盖；已有可读取的普通文件软链接会被保留。缺少 `HOME`、无法创建目录、损坏软链接或配置路径不是可读普通文件时，启动器报错并停止。

从 AUR 安装迁移时，先退出 Typora，把原来的 `settings.user.toml` 备份并复制到上述用户目录，再启动本包。可能的旧文件位置是原安装目录中的 `resources/plugin/global/settings/settings.user.toml`，具体路径以旧版实际安装布局为准。

手工设置示例：

```toml
[global]
ENABLE = true

[updater]
ENABLE = false
```

配置合并、保存和迁移由上游插件负责。启动器只负责首次创建以及路径检查，不会在每次启动时重写用户文件。Nix store 中的默认配置和插件代码不可写。

Home Manager 可以声明配置文件，但 `home.file.<name>.text` 或 `source` 指向 Nix store 时，插件只能读取它，无法在设置界面保存；插件自身的自动迁移也可能尝试写入。需要在插件界面修改设置时，应保留普通用户文件，或用 Home Manager 的 `config.lib.file.mkOutOfStoreSymlink` 指向预先创建的、用户可写的 TOML 文件。不要通过放宽整个安装目录权限来解决。

## 相对 AUR 的处理

AUR 包依赖 `electron13`，替换部分共享运行时资源，并在桌面启动命令中添加 `--no-sandbox`。本包保留上游 Debian 包里的 Electron 运行时，以 `autoPatchelfHook` 和显式 Nix 依赖修补 ELF 路径，不依赖 Arch 的 `/usr/lib/electron13`。

运行时显式提供 `libudev.so.1` 所在的 udev 库路径，处理旧 Electron 通过动态加载访问 udev 的情况；这类加载不能仅靠扫描 ELF 的直接依赖解决。

构建时检查唯一的 `window.html`，在预期的 `frame.js` 标签后注入一次 `plugin/index.js`。资源布局、注入点或插件默认 updater 配置变化时，构建会失败，要求维护者检查。

AUR 的 `typora-free-with-plugin.install` 在 `post_install()` 中将 `/usr/lib/typora-free-with-plugin/resources/plugin` 设为 `chmod 777`，并将其中 `global/settings/settings.user.toml` 设为 `chmod 666`；`post_upgrade()` 再调用 `post_install()`。这是让普通用户写入共享安装目录的处理。

Nix 包不运行这些 pacman 钩子，也不改变 store 写权限：插件代码和默认配置留在不可变安装目录，启动器在 `$HOME/.config/typora_plugin/settings.user.toml` 初始化权限为 `0600` 的用户文件。安装和升级都通过新 derivation 完成，已有用户文件保留。插件默认 updater 关闭；用户已有配置若显式重新开启 updater，将覆盖该默认值，应手工保持关闭。

包默认没有添加 `--no-sandbox`。需要的运行参数可以通过命令行或 `extraFlags` 显式传入。

## GitHub Actions

[`ci.yml`](../.github/workflows/ci.yml) 在 pull request 和推送到 `main` 时运行：

1. 从 `packages.x86_64-linux` 自动枚举并构建所有包，因此包含 `typora`。
2. 单独构建 `typora.tests.layout`、`typora.tests.runtime`、`typora.tests.gui`。
3. 执行插件更新逻辑的离线单元检查。

[`update.yml`](../.github/workflows/update.yml) 保留手动触发，以及每周一 **12:17（Asia/Shanghai，04:17 UTC）** 的原有计划。每日 **00:00（Asia/Shanghai，对应前一日 16:00 UTC）** 的 `github-rev` 计划继续只更新这类条目，例如 DedSec 主题，不处理 Typora 插件。`updates.nix` 中的 `typora` 项使用 `kind = "typora-plugin"`，由手动触发或每周计划处理：

- 仅跟随 `obgnail/typora_plugin` 的最新稳定 release，更新 `pluginVersion` 和 `plugin` 源记录。
- 使用实际 release tag，兼容有或没有 `v` 前缀；要求存在匹配的发布 ZIP，并重新预取 SHA-256。
- 编辑器仍固定为免费 beta `0.11.18`，两个架构的 Typora URL 和散列不随插件升级而改动。
- 当插件来源文件改变时，先构建 `typora` 与布局、启动器、GUI 检查；通过后提交并推送到 `main`。

GUI 检查覆盖窗口创建和插件初始化。自动提交只覆盖来源记录；仍应在日常图形环境中验证实际使用的编辑、导出及插件功能。

## 更新与回滚

插件常规更新由上述 Actions 直接提交到 `main`。手动升级时：

1. 选择上游发布版本，确认支持当前免费 beta 及其 Electron/Node 版本。
2. 修改 `sources.nix` 中对应版本、URL 和散列。更改 Typora 本体时需同时处理两个架构，不能只换一个版本字符串。
3. 用 `nix store prefetch-file --hash-type sha256 --json URL` 获取下载文件的 SRI 散列，并核查所下载的发布内容。
4. 运行下列检查，最后在图形会话中检查编辑器、插件设置和关键功能。

```sh
nix build --no-link .#typora .#typora.tests.layout .#typora.tests.runtime .#typora.tests.gui
python3 -m unittest discover -s scripts -p 'test_update_typora.py' -v
```

升级不使用插件内置的在线 updater，也不运行上游针对系统安装目录的卸载脚本。删除 profile 或系统配置中的包即可卸载程序；home 目录中的用户配置自行保留或备份后删除。

通过原有 profile generation 或 NixOS generation 回滚程序包。用户配置保存在 home 目录，回滚软件包不会同步回滚配置；升级前应自行备份，以防新旧插件配置格式不同。

## 故障排查与验证范围

- **出现另一版 Typora**：检查 overlay 是否应用，以及 `which typora` 是否指向预期 profile。nixpkgs 自带正式版与本包同名，应在同一 profile 中选择一个。
- **无法创建或读取设置文件**：检查 `HOME`、用户目录权限、配置路径是否为普通文件，以及软链接目标是否存在。
- **插件设置不能保存**：检查配置及父目录是否用户可写；指向 Nix store 的声明式文件无法通过插件修改。
- **没有插件菜单**：确认使用本包启动，并检查开发者控制台和插件日志。自定义 ZIP 必须保留发布包预期布局。
- **图形窗口打不开**：确认处于可用 X11/Wayland 会话，检查显示环境变量和显卡驱动。需要时临时尝试 `typora --disable-gpu` 以定位渲染问题。
- **沙箱报错**：部分环境的旧 Electron 无法启用 Chromium 沙箱。可显式尝试 `typora --no-sandbox` 或相应 `extraFlags`；该参数会降低渲染进程隔离，仅在了解影响后使用。
- **升级插件后出错**：回退插件固定版本并重建。新的插件可能依赖旧 beta 运行时不具备的浏览器或 Node API。

本次迁移已在 x86_64 上完成实际构建、安装布局检查、启动器运行检查和虚拟显示 GUI 检查。GUI 运行使用 `--no-sandbox --disable-gpu`，实际创建了窗口，插件加载结果为 **45 个启用、0 个错误**。

这覆盖了固定版本组合在测试环境中的启动和插件初始化，不代表所有插件功能、硬件 GPU、原生 Wayland 或 aarch64 均已验证。arm64 目前仅提供固定源记录，仍需在对应架构上构建和运行。
