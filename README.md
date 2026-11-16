# nur-packages

JimmyWang0417 的 NUR 仓库。nixpkgs 固定在 `github:NixOS/nixpkgs/nixos-26.05`。完整调用约定在 [docs/接口.md](docs/接口.md)。

主题包和每日更新在 nur-packages，nixos-config 只引用。

`nixpkgs.config.allowUnfree` 必须为真，否则 `xjtu-course-genius` 在求值时会被 nixpkgs 拒绝。

## 已打包

| 属性 | 版本 | 来源 | 相对 AUR 改了什么 | 能否被 nixos-config 引用 |
| --- | --- | --- | --- | --- |
| `crm` | 0.2.2 | [AUR crm](https://aur.archlinux.org/packages/crm)，上游 [wtklbm/crm](https://github.com/wtklbm/crm) | AUR 构建时 `cargo update -w`。这里用 `buildRustPackage` 和提交的 `Cargo.lock` | 可以，`pkgs.crm` |
| `animeko` | 6.4.0 | 官方 AppImage。写法来自 [Hobr/my-nix](https://github.com/Hobr/my-nix/blob/84157405e310f2b6c9b35d719acfba74c4cd04e7/nix/packages/animeko.nix)。AUR 是 [animeko-appimage](https://aur.archlinux.org/packages/animeko-appimage) | 保留 AppImage/`wrapType2`，安装 desktop 和 icon。不把 Hobr 的整份 flake 加为 input | 可以，`pkgs.animeko` |
| `botmux` | 3.59.15 | [deepcoldy/botmux](https://github.com/deepcoldy/botmux/releases/tag/v3.59.15) | `fetchurl` 安装官方 ELF，并把 `tmux` 放进 `PATH` | 可以，`pkgs.botmux` |
| `xjtutoolbox` | 1.4.1 | [yan-xiaoo/XJTUToolBox](https://github.com/yan-xiaoo/XJTUToolBox/releases/tag/v1.4.1) 的 AppImage | 不再拆 AUR 用的 pacman `.pkg.tar.zst` | 可以，`pkgs.xjtutoolbox` |
| `xjtu-course-genius` | 4.6.1 | [Hz162/XJTU-Course-Genius](https://github.com/Hz162/XJTU-Course-Genius/releases/tag/v4.6.1) 的 deb | AUR 仓库是空的，直接取 GitHub release | 可以，需要 `allowUnfree` |
| `grub-theme-dedsec` | 0-unstable-2025-10-24 | [VandalByte/dedsec-grub2-theme](https://github.com/VandalByte/dedsec-grub2-theme) `bbfe078386545688727f44897a7fede8af2c6dda` | 装 fuckery、1440p、彩色图标。没有 AUR 包 | 可以，`pkgs.grub-theme-dedsec`。每日 `github-rev` 更新也在本仓库 |
| `whitesur-kde` | 0-unstable-2024-10-12 | [vinceliuice/WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde) 壁纸 `eb7b054b1c7c3429965e3b531de2db38e2c83aec`，装饰 `36dfbd08b1cdd408c61c986b900b3b45fc98776d` | 壁纸是浅色与深色 `3840x2160.png`。装饰是 `aurorae/WhiteSur/`。没有 AUR 包 | 可以，`pkgs.whitesur-kde`。每日 `github-rev` 更新也在本仓库，两对 rev 都跟着默认分支 HEAD |
| `tela-icon-theme` | 0-unstable-2026-08-10 | [vinceliuice/Tela-icon-theme](https://github.com/vinceliuice/Tela-icon-theme) `a1fffc5bfab716bd022dd228ee96fe3965cdb33d` | 只装标准色、目录名 `Tela`。不装 `Tela-dark` / `Tela-light`，也不改色 | 可以，`pkgs.tela-icon-theme`。每日 `github-rev` 更新也在本仓库 |

## 未打包

- `alder`、`grok-bot`：按要求不收录。
- 宿主机 EasyConnect 客户端（官方 deb）：按要求不收录。`docker-easyconnect` 是 nixos-config 里的服务，不是本仓库的包。
- `udf-http-range-proxy`、`keepassxc-unlock`、`verilog-format`：按要求不收录。
- `typora-free-with-plugin`、`typora-crack`、`typora-unlock`：破解或补丁包，不收录。官方 Typora deb 没有打进仓库。
- `anaconda`：官方安装器约 1.0 GiB，现成写法会装进 `~/.conda`，不是 Nix store 前缀。
- `huaweicloud-meeting`：官方 URL 当前返回 arm64 8.11.1，不是 x86_64。AUR 使用的是镜像站地址。
- `zju-connect`、`docker-easyconnect`、`aTrust`：不收录。

```bash
nix --extra-experimental-features 'nix-command flakes' build --no-link .#animeko
```
