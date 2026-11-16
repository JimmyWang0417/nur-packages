{ pkgs }:
{
  animeko = pkgs.callPackage ./pkgs/animeko { };
  botmux = pkgs.callPackage ./pkgs/botmux { };
  crm = pkgs.callPackage ./pkgs/crm { };
  grub-theme-dedsec = pkgs.callPackage ./pkgs/grub-theme-dedsec { };
  xjtu-course-genius = pkgs.callPackage ./pkgs/xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./pkgs/xjtutoolbox { };
}
