# nur-packages

JimmyWang0417 的 NUR 仓库。nixpkgs 固定在 `github:NixOS/nixpkgs/nixos-26.05`。完整调用约定在 [docs/接口.md](docs/接口.md)。

主题包和每日更新在 nur-packages，nixos-config 只引用。

`nixpkgs.config.allowUnfree` 必须为真，否则 `xjtu-course-genius` 在求值时会被 nixpkgs 拒绝。

## 已打包

| 属性 | 版本 | 来源 | 相对 AUR 改了什么 | 能否被 nixos-config 引用 |
| --- | --- | --- | --- | --- |
| `crm` | 0.2.2 | [AUR crm](https://aur.archlinux.org/packages/crm)，上游 [wtklbm/crm](https://github.com/wtklbm/crm) | AUR 构建时 `cargo update -w`。这里用 `buildRustPackage` 和提交的 `Cargo.lock` | 可以，`pkgs.crm` |
| `animeko` | 6.4.0 | [open-ani/animeko](https://github.com/open-ani/animeko/releases/tag/v6.4.0) v6.4.0 官方 AppImage | 不采用 AUR `animeko-appimage` 的 PKGBUILD。`fetchurl` 固定哈希，`wrapType2` 提供 `animeko`，桌面项用 `makeDesktopItem`，图标取自 AppImage | 可以，`pkgs.animeko` |
| `botmux` | 3.59.15 | [deepcoldy/botmux](https://github.com/deepcoldy/botmux/releases/tag/v3.59.15) | `fetchurl` 安装官方 ELF，并把 `tmux` 放进 `PATH` | 可以，`pkgs.botmux` |
| `xjtutoolbox` | 1.4.1 | [yan-xiaoo/XJTUToolBox](https://github.com/yan-xiaoo/XJTUToolBox/releases/tag/v1.4.1) 的 AppImage | 不再拆 AUR 用的 pacman `.pkg.tar.zst` | 可以，`pkgs.xjtutoolbox` |
| `xjtu-course-genius` | 4.6.1 | [Hz162/XJTU-Course-Genius](https://github.com/Hz162/XJTU-Course-Genius/releases/tag/v4.6.1) 的 deb | AUR 仓库是空的，直接取 GitHub release | 可以，需要 `allowUnfree` |
| `grub-theme-dedsec` | 0-unstable-2025-10-24 | [VandalByte/dedsec-grub2-theme](https://github.com/VandalByte/dedsec-grub2-theme) `bbfe078386545688727f44897a7fede8af2c6dda` | 装 fuckery、1440p、彩色图标。没有 AUR 包 | 可以，`pkgs.grub-theme-dedsec`。每日 `github-rev` 更新也在本仓库 |
| `whitesur-kde` | 0-unstable-2024-10-12 | [vinceliuice/WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde) 壁纸 `eb7b054b1c7c3429965e3b531de2db38e2c83aec`，装饰 `36dfbd08b1cdd408c61c986b900b3b45fc98776d` | 壁纸是浅色与深色 `3840x2160.png`。装饰是 `aurorae/WhiteSur/`。没有 AUR 包 | 可以，`pkgs.whitesur-kde`。不在 `updates.nix` 里，两对 rev 不跟默认分支一起改 |
| `tela-icon-theme` | 0-unstable-2026-08-10 | [vinceliuice/Tela-icon-theme](https://github.com/vinceliuice/Tela-icon-theme) `a1fffc5bfab716bd022dd228ee96fe3965cdb33d` | 只装标准色、目录名 `Tela`。不装 `Tela-dark` / `Tela-light`，也不改色 | 可以，`pkgs.tela-icon-theme`。每日 `github-rev` 更新也在本仓库 |

```bash
nix --extra-experimental-features 'nix-command flakes' build --no-link .#animeko
```
