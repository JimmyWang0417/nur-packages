{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:
buildNpmPackage (finalAttrs: {
  pname = "alder";
  version = "2.0.0";

  src = fetchFromGitHub {
    owner = "aweary";
    repo = "alder";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ZfcH+UhvrRkAfJvxIb2YCgB3CJphWy0a3yU7zXo0JOI=";
  };

  # AUR installs the npm tarball with `npm install -g`. Upstream is the Node
  # package @aweary/alder and has no Cargo.toml. This expression vendors the
  # same 2.0.0 sources and installs the `alder` bin through buildNpmPackage.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-fwtnhOBioEuR2E39nkylMS79HlcYeIUfyHw25RehUgM=";
  dontNpmBuild = true;

  meta = {
    description = "A minimal implementation of the UNIX tree command with colors";
    homepage = "https://github.com/aweary/alder";
    license = lib.licenses.mit;
    mainProgram = "alder";
  };
})
