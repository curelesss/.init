# mime-apps.nix
{ ... }:

let
  videoPlayer = "mpv.desktop";
in
{
  xdg.mime.defaultApplications = {
    # Video
    "video/mp4"         = videoPlayer;
    "video/mkv"         = videoPlayer;
    "video/x-matroska"  = videoPlayer;
    "video/avi"         = videoPlayer;
    "video/webm"        = videoPlayer;
    "video/quicktime"   = videoPlayer;
    "video/x-msvideo"   = videoPlayer;
  };
}
