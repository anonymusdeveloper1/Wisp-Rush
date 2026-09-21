import { Config } from "@remotion/cli/config";

/**
 * The asset workspace is the repo's git-ignored video/ folder — footage, game audio, graphics and
 * voice. staticFile("footage/x.mp4") resolves there, so nothing is duplicated into this project.
 */
Config.setPublicDir("../../../video");
Config.setVideoImageFormat("jpeg");
Config.setCodec("h264");
Config.setCrf(16);
Config.setChromiumOpenGlRenderer("angle");
