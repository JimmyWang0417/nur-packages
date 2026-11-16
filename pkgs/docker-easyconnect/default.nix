{
  dockerTools,
  lib,
}:
let
  # GUI image with VNC. Upstream documents 7.6.7 as the stable GUI tag;
  # 7.6.8 is command-line only. Tag updates are not in updates.nix:
  # scripts/update.py has no OCI kind, so this digest stays pinned.
  image = dockerTools.pullImage {
    imageName = "hagb/docker-easyconnect";
    imageDigest = "sha256:40c411e71198111871ac281cee78ff0ae961139897674c7df8fa5eec0da78e80";
    finalImageTag = "7.6.7";
    os = "linux";
    arch = "amd64";
    hash = "sha256-sWe54yP3l0SPjOJKOeGBRhZgEY5jF0nhYM3gJuScWyw=";
  };
in
image.overrideAttrs (old: {
  meta = {
    description = "Sangfor EasyConnect 7.6.7 GUI client from hagb/docker-easyconnect";
    homepage = "https://github.com/docker-easyconnect/docker-easyconnect";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
  passthru = (old.passthru or { }) // {
    imageRef = "${old.imageName}:${old.imageTag}";
    # Ports the upstream GUI `docker run` publishes on localhost.
    ports = [
      "127.0.0.1:5901:5901" # VNC
      "127.0.0.1:1080:1080" # SOCKS
      "127.0.0.1:8888:8888" # HTTP proxy
    ];
  };
})
