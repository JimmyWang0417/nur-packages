{ pkgs }:
{
  alder = pkgs.callPackage ./pkgs/alder { };
  animeko = pkgs.callPackage ./pkgs/animeko { };
  botmux = pkgs.callPackage ./pkgs/botmux { };
  crm = pkgs.callPackage ./pkgs/crm { };
  easyconnect = pkgs.callPackage ./pkgs/easyconnect { };
  grok-bot = pkgs.callPackage ./pkgs/grok-bot { };
  typora = pkgs.callPackage ./pkgs/typora { };
  xjtu-course-genius = pkgs.callPackage ./pkgs/xjtu-course-genius { };
  xjtutoolbox = pkgs.callPackage ./pkgs/xjtutoolbox { };
}
