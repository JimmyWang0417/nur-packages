# Weekly update allow-list. scripts/update.py and .github/workflows/update.yml
# read this file with `nix eval --file ./updates.nix --json`.
# A package is updated only when it appears here.
[
  {
    attribute = "qoder-cn";
    file = "pkgs/qoder-cn/default.nix";
    owner = "";
    repo = "";
    kind = "http-version";
    asset = "";
    versionUrl = "https://qoder-app.oss-cn-beijing.aliyuncs.com/qoder-app/releases/latest/Qoder-CN-linux-amd64.deb";
    versionHeader = "x-oss-meta-version";
    fileUrl = "https://qoder-app.oss-cn-beijing.aliyuncs.com/qoder-app/releases/{version}/Qoder-CN-linux-amd64.deb";
  }
  {
    attribute = "qoder";
    file = "pkgs/qoder/default.nix";
    owner = "";
    repo = "";
    kind = "http-version";
    asset = "";
    versionUrl = "https://download.qoder.com/qoder-app/releases/latest-linux.yml";
    versionHeader = "";
    versionPattern = "(?m)^version:\\s*(\\S+)";
    fileUrl = "https://download.qoder.com/qoder-app/releases/{version}/Qoder-linux-amd64.deb";
  }
  {
    attribute = "trae-cn";
    file = "pkgs/trae-cn/default.nix";
    owner = "";
    repo = "";
    kind = "http-version";
    asset = "";
    versionUrl = "https://api.trae.ai/icube/api/v1/native/version/trae/cn/latest";
    versionHeader = "";
    versionPattern = "https://lf-cdn\\.trae\\.com\\.cn/obj/trae-com-cn/pkg/app/releases/stable/([^/]+)/linux/TRAE_CN-linux-x64\\.deb";
    fileUrl = "https://lf-cdn.trae.com.cn/obj/trae-com-cn/pkg/app/releases/stable/{version}/linux/TRAE_CN-linux-x64.deb";
  }
  {
    attribute = "typora";
    file = "pkgs/typora/sources.nix";
    owner = "obgnail";
    repo = "typora_plugin";
    kind = "typora-plugin";
    asset = "typora-plugin@v{version}.zip";
  }
  {
    attribute = "animeko";
    file = "pkgs/animeko/default.nix";
    owner = "open-ani";
    repo = "animeko";
    kind = "github-asset";
    asset = "ani-{version}-linux-x86_64.appimage";
  }
  {
    attribute = "claude-cage";
    file = "pkgs/claude-cage/default.nix";
    owner = "Lee-xeo";
    repo = "Claude-Cage";
    kind = "github-asset";
    asset = "Cage-{version}-linux-amd64.deb";
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
  {
    attribute = "tela-icon-theme";
    file = "pkgs/tela-icon-theme/default.nix";
    owner = "vinceliuice";
    repo = "Tela-icon-theme";
    kind = "github-rev";
    asset = "";
  }
  {
    attribute = "whitesur-kde";
    file = "pkgs/whitesur-kde/default.nix";
    owner = "vinceliuice";
    repo = "WhiteSur-kde";
    kind = "github-rev";
    asset = "";
  }

  {
    attribute = "breath-wallpapers";
    file = "pkgs/breath-wallpapers/default.nix";
    owner = "manjaro-contrib";
    repo = "artwork-themes-breath";
    kind = "github-rev";
    asset = "";
  }
  {
    attribute = "endeavouros-wallpapers";
    file = "pkgs/endeavouros-wallpapers/default.nix";
    owner = "endeavouros-team";
    repo = "Branding";
    kind = "github-rev";
    asset = "";
  }
  {
    attribute = "endeavouros-community-wallpapers";
    file = "pkgs/endeavouros-community-wallpapers/default.nix";
    owner = "EndeavourOS-Community-Editions";
    repo = "Community-wallpapers";
    kind = "github-rev";
    asset = "";
  }
  {
    attribute = "deveco-studio";
    file = "pkgs/deveco-studio/default.nix";
    owner = "alex3236";
    repo = "devecostudio-linux";
    kind = "github-version";
    asset = "";
  }
]
