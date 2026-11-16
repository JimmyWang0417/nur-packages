{ pkgs }:
{
  alder = pkgs.callPackage ./pkgs/alder { };
  animeko = pkgs.callPackage ./pkgs/animeko { };
  botmux = pkgs.callPackage ./pkgs/botmux { };
  crm = pkgs.callPackage ./pkgs/crm { };
  easyconnect = pkgs.callPackage ./pkgs/easyconnect { };
  grok-bot = pkgs.callPackage ./pkgs/grok-bot { };
  grub-theme-dedsec = pkgs.callPackage ./pkgs/grub-theme-dedsec { };
  xjtu-course-genius = pkgs.callPackage ./pkgs/xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./pkgs/xjtutoolbox { };
}
