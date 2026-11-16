# Weekly update allow-list. scripts/update.py and .github/workflows/update.yml
# read this file with `nix eval --file ./updates.nix --json`.
# A package is updated only when it appears here.
[
  {
    attribute = "animeko";
    file = "pkgs/animeko/default.nix";
    owner = "open-ani";
    repo = "animeko";
    kind = "github-asset";
    asset = "ani-{version}-linux-x86_64.appimage";
  }
  {
    attribute = "botmux";
    file = "pkgs/botmux/default.nix";
    owner = "deepcoldy";
    repo = "botmux";
    kind = "github-asset";
    asset = "botmux-linux-x64";
  }
  {
    attribute = "xjtutoolbox";
    file = "pkgs/xjtutoolbox/default.nix";
    owner = "yan-xiaoo";
    repo = "XJTUToolBox";
    kind = "github-asset";
    asset = "XJTUToolbox-linux-x86_64.AppImage";
  }
  {
    attribute = "xjtu-course-genius";
    file = "pkgs/xjtu-course-genius/default.nix";
    owner = "Hz162";
    repo = "XJTU-Course-Genius";
    kind = "github-asset";
    asset = "XJTU-Course-Genius-linux-x64.deb";
  }
  {
    attribute = "crm";
    file = "pkgs/crm/default.nix";
    owner = "wtklbm";
    repo = "crm";
    kind = "github-source";
    asset = "";
  }
  {
    attribute = "grub-theme-dedsec";
    file = "pkgs/grub-theme-dedsec/default.nix";
    owner = "VandalByte";
    repo = "dedsec-grub2-theme";
    kind = "github-rev";
    asset = "";
  }
]
