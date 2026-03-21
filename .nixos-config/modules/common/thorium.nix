{ pkgs, thorium, ... }:

{
  environment.systemPackages = [
    thorium.packages."x86_64-linux".thorium-avx2  # change to avx/sse4/sse3 if needed
  ];
}
