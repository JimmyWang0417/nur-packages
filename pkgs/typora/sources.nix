# AUR typora-free-with-plugin 1.19.16-1, checked on 2026-11-16.
# Typora and its plugin have independent version numbers.
{
  typoraVersion = "0.11.18";
  pluginVersion = "1.19.16";
  typora = {
    x86_64-linux = {
      url = "https://github.com/wyf9661/typora-free/releases/download/v0.11.18/typora_0.11.18_amd64.deb";
      hash = "sha256-ogKTWnVMS3NEzJR9sUPhKIXkpxbKX3D2B/AxjDRrtsY=";
    };
    aarch64-linux = {
      url = "https://github.com/wyf9661/typora-free/releases/download/v0.11.18/typora_0.11.18_arm64.deb";
      hash = "sha256-Eq1GcyxNp9lBRwHFhP7pQrr4O4kWVWPxi6A9hZ61mtg=";
    };
  };
  plugin = {
    url = "https://github.com/obgnail/typora_plugin/releases/download/1.19.16/typora-plugin@v1.19.16.zip";
    hash = "sha256-bLLZ0dFyChx42qnpPTTwyTR4INkEmwduelSL5aco7+M=";
  };
}
