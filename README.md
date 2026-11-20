# nur-packages

JimmyWang0417 的 NUR 仓库。nixpkgs 固定在 `github:NixOS/nixpkgs/nixos-26.05`。完整调用约定在 [docs/接口.md](docs/接口.md)。

主题包和每日更新都在本仓库。调用方只引用输出。

`nixpkgs.config.allowUnfree` 必须为真，否则 `xjtu-course-genius`、`typora` 在求值时会被 nixpkgs 拒绝。

## 已打包

| 属性 | 版本 | 来源 | 相对 AUR 改了什么 | 如何引用 |
| --- | --- | --- | --- | --- |
| `crm` | 0.2.2 | [AUR crm](https://aur.archlinux.org/packages/crm)，上游 [wtklbm/crm](https://github.com/wtklbm/crm) | AUR 构建时 `cargo update -w`。这里用 `buildRustPackage` 和提交的 `Cargo.lock` | 可以，`pkgs.crm` |
| `docker-easyconnect` | 7.6.7 | [hagb/docker-easyconnect](https://github.com/docker-easyconnect/docker-easyconnect) 的 GUI 镜像 | 不安装宿主机 Sangfor deb。`dockerTools.pullImage` 钉住 linux/amd64 的镜像 digest。上游 GUI 在 localhost 发布 `5901`、`1080`、`8888` | 可以，`pkgs.docker-easyconnect`。`updates.nix` 还不跟踪 OCI tag |
| `animeko` | 6.4.0 | [open-ani/animeko](https://github.com/open-ani/animeko/releases/tag/v6.4.0) v6.4.0 官方 AppImage | 不采用 AUR `animeko-appimage` 的 PKGBUILD。`fetchurl` 固定哈希，`wrapType2` 提供 `animeko`，桌面项用 `makeDesktopItem`，图标取自 AppImage | 可以，`pkgs.animeko` |
| `botmux` | 3.59.15 | [deepcoldy/botmux](https://github.com/deepcoldy/botmux/releases/tag/v3.59.15) | `fetchurl` 安装官方 ELF，并把 `tmux` 放进 `PATH` | 可以，`pkgs.botmux` |
| `claude-cage` | 0.1.8 | [Lee-xeo/Claude-Cage](https://github.com/Lee-xeo/Claude-Cage/releases/tag/v0.1.8) 官方 `Cage-0.1.8-linux-amd64.deb` | AUR `claude-cage-bin` 仍是 0.1.7rc.1。这里 `fetchurl` 固定 0.1.8，解包官方 deb，并把 QEMU、OpenSSH、git 放进 `PATH` | 可以，`pkgs.claude-cage`。每周 `github-asset` 更新也在本仓库 |
| `cc-switch` | 4.0.36 | [farion1231/cc-switch](https://github.com/farion1231/cc-switch/releases/tag/v4.0.36) 官方 `CC-Switch-v4.0.36-Linux-x86_64.deb` | 本机 AUR `cc-switch-bin` 是 4.0.32，锁定的 nixpkgs-unstable 是 3.16.5。这里 `fetchurl` 固定当前官方 4.0.36，解包官方 deb | 可以，`pkgs.cc-switch`。每周 `github-asset` 更新也在本仓库 |
| `qoder-cn` | 0.5.16 | [Qoder CN](https://qoder.com.cn) 官方 `Qoder-CN-linux-amd64.deb` | nixpkgs 和 NUR 都没有跟上的包。NUR `Sittymin.qoder-cn` 仍是 0.2.2。这里 `fetchurl` 固定 0.5.16，解包官方 deb | 可以，需要 `allowUnfree`。系统安装这个。每日 `http-version` 更新也在本仓库 |
| `qoder` | 0.5.16 | [Qoder](https://qoder.com) 官方 `Qoder-linux-amd64.deb` | 国际版，和 `qoder-cn` 不是同一个 deb。nixpkgs 和 NUR 都没有这份 | 可以，需要 `allowUnfree`。不作为系统默认安装。每日 `http-version` 读 `latest-linux.yml` |
| `trae-cn` | 2.3.105403 | [Trae CN](https://www.trae.com.cn/) 官方 `TRAE_CN-linux-x64.deb`，应用版本 3.4.22 | 国际版继续用 NUR `lonerOrz.trae`，这里不复制。版本号是 CDN 构建号 | 可以，需要 `allowUnfree`。系统安装这个。每日 `http-version` 读中国版清单 |
| `xjtutoolbox` | 1.4.1 | [yan-xiaoo/XJTUToolBox](https://github.com/yan-xiaoo/XJTUToolBox/releases/tag/v1.4.1) 的 AppImage | 不再拆 AUR 用的 pacman `.pkg.tar.zst` | 可以，`pkgs.xjtutoolbox` |
| `xjtu-course-genius` | 4.6.1 | [Hz162/XJTU-Course-Genius](https://github.com/Hz162/XJTU-Course-Genius/releases/tag/v4.6.1) 的 deb | AUR 仓库是空的，直接取 GitHub release | 可以，需要 `allowUnfree` |
| `grub-theme-dedsec` | 0-unstable-2025-10-24 | [VandalByte/dedsec-grub2-theme](https://github.com/VandalByte/dedsec-grub2-theme) `bbfe078386545688727f44897a7fede8af2c6dda` | 装 fuckery、1440p、彩色图标。没有 AUR 包 | 可以，`pkgs.grub-theme-dedsec`。每日 `github-rev` 更新也在本仓库 |
| `whitesur-kde` | 0-unstable-2026-08-07 | [vinceliuice/WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde) `cf4df59ce91004f7ea39358b1b8ff917d5c329f7` | 壁纸是 `wallpaper/WhiteSur` 的浅色与深色 `3840x2160.jpg`。装饰由 `aurorae/main/WhiteSur/` 装成 `WhiteSur`。没有 AUR 包 | 可以，`pkgs.whitesur-kde`。每日 `github-rev` 更新也在本仓库 |
| `breath-wallpapers` | 0-unstable-2024-06-07 | [manjaro-contrib/artwork-themes-breath](https://github.com/manjaro-contrib/artwork-themes-breath) `1b708941f52be6f36ed61635659ad1d26c5719d7`，镜像 [code.manjaro.org/artwork/breath](https://code.manjaro.org/artwork/breath) | 装 Bamboo、Bamboo at Night、North、Foreland 到 `share/wallpapers`。没有 AUR 包 | 可以，`pkgs.breath-wallpapers`。每日 `github-rev` 更新也在本仓库 |
| `endeavouros-wallpapers` | 0-unstable-2026-07-21 | [endeavouros-team/Branding](https://github.com/endeavouros-team/Branding) `b0b0b3453216d2e1daacd0dd20ecdbe697ae098a` | 装当前官方默认壁纸和浅色壁纸到 `share/wallpapers`。没有 AUR 包 | 可以，`pkgs.endeavouros-wallpapers`。每日 `github-rev` 更新也在本仓库 |
| `endeavouros-community-wallpapers` | 0-unstable-2026-11-16 | [EndeavourOS-Community-Editions/Community-wallpapers](https://github.com/EndeavourOS-Community-Editions/Community-wallpapers) `358c0cee2f628c3c582c5a4e531b9ef2c79abc77` | 装 classic 与 community 目录里的壁纸到 `share/wallpapers`。没有 AUR 包 | 可以，`pkgs.endeavouros-community-wallpapers`。每日 `github-rev` 更新也在本仓库 |
| `tela-icon-theme` | 0-unstable-2026-08-10 | [vinceliuice/Tela-icon-theme](https://github.com/vinceliuice/Tela-icon-theme) `a1fffc5bfab716bd022dd228ee96fe3965cdb33d` | 只装标准色、目录名 `Tela`。不装 `Tela-dark` / `Tela-light`，也不改色 | 可以，`pkgs.tela-icon-theme`。每日 `github-rev` 更新也在本仓库 |
| `typora` | 0.11.18 + 插件 1.19.16 | [AUR typora-free-with-plugin](https://aur.archlinux.org/packages/typora-free-with-plugin)；固定 GitHub release | 免费 beta 搭配插件；用户配置保存在 home；保留来源、插件和启动参数覆盖接口；接入构建、GUI 检查和每周插件更新。详见 [Typora 文档](docs/typora.md) | 可以，需要 `allowUnfree` |

```bash
nix --extra-experimental-features 'nix-command flakes' build --no-link .#animeko
nix --extra-experimental-features 'nix-command flakes' build --no-link .#typora
```
