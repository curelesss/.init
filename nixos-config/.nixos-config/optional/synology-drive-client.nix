{ config, pkgs, lib, ... }:

let
  synology-drive-client = pkgs.stdenv.mkDerivation {
    pname = "synology-drive-client";
    version = "4.0.2-17889";
    src = pkgs.fetchurl {
      url = "https://cndl.synology.cn/download/Utility/SynologyDriveClient/4.0.2-17889/Ubuntu/Installer/synology-drive-client-17889.x86_64.deb?model=DS918%2B&bays=4&dsm_version=7.3.2&build_number=86009";
      sha256 = "sha256-refsAzqYmKAr107D4HiJViBQE1Qa6QoOECtX+TPjSwU=";
    };
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];
    dontWrapQtApps = true;
    buildInputs = with pkgs; [
      glib
      nautilus
      gtk3
      xorg.libSM
      xorg.libICE
      qt5.qtbase
      qt5.qtdeclarative
      qt5.qtquickcontrols2
    ];
    autoPatchelfIgnoreMissingDeps = [
      "libnautilus-extension.so.1"
      "libnautilus-extension.so.4"
      "libQt5Pdf.so.5"
      "libQt5QuickWidgets.so.5"
    ];
    unpackPhase = "dpkg-deb -x $src .";
    installPhase = ''
      mkdir -p $out
      cp -r usr/* $out/

      mkdir -p $out/opt/Synology
      cp -r opt/Synology/SynologyDrive $out/opt/Synology/

      substituteInPlace $out/bin/synology-drive \
        --replace '/opt/Synology/SynologyDrive' "$out/opt/Synology/SynologyDrive"
    '';
  };
in
{
  environment.systemPackages = [ synology-drive-client ];
}
