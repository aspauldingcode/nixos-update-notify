{ lib
, stdenv
, cmake
, ninja
, extra-cmake-modules
, qt6
, kdePackages
, channel ? "nixos-unstable"
}:

stdenv.mkDerivation {
  pname = "nixos-discover-backend";
  version = "1.0.0";

  src = ./discover-backend;

  nativeBuildInputs = [
    cmake
    ninja
    extra-cmake-modules
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    kdePackages.kcoreaddons
    kdePackages.ki18n
    kdePackages.discover
  ];

  cmakeFlags = [
    "-DKDE_INSTALL_PLUGINDIR=${placeholder "out"}/lib/qt-6/plugins"
  ];

  meta = with lib; {
    description = "KDE Discover backend for NixOS system updates";
    homepage = "https://github.com/erichelgeson/nixos-update-notify";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
