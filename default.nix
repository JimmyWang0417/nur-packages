{ pkgs }:
{
  animeko = pkgs.callPackage ./pkgs/animeko { };
  botmux = pkgs.callPackage ./pkgs/botmux { };
  breath-wallpapers = pkgs.callPackage ./pkgs/breath-wallpapers { };
  crm = pkgs.callPackage ./pkgs/crm { };
  docker-easyconnect = pkgs.callPackage ./pkgs/docker-easyconnect { };
  endeavouros-community-wallpapers = pkgs.callPackage ./pkgs/endeavouros-community-wallpapers { };
  endeavouros-wallpapers = pkgs.callPackage ./pkgs/endeavouros-wallpapers { };
  grub-theme-dedsec = pkgs.callPackage ./pkgs/grub-theme-dedsec { };
  tela-icon-theme = pkgs.callPackage ./pkgs/tela-icon-theme { };
  whitesur-kde = pkgs.callPackage ./pkgs/whitesur-kde { };
  xjtu-course-genius = pkgs.callPackage ./pkgs/xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./pkgs/xjtutoolbox { };
}
