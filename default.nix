{ pkgs }:
{
  animeko = pkgs.callPackage ./pkgs/animeko { };
  botmux = pkgs.callPackage ./pkgs/botmux { };
  crm = pkgs.callPackage ./pkgs/crm { };
  grub-theme-dedsec = pkgs.callPackage ./pkgs/grub-theme-dedsec { };
  tela-icon-theme = pkgs.callPackage ./pkgs/tela-icon-theme { };
  whitesur-kde = pkgs.callPackage ./pkgs/whitesur-kde { };
  xjtu-course-genius = pkgs.callPackage ./pkgs/xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./pkgs/xjtutoolbox { };
}
