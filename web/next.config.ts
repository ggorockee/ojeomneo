import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  basePath: "/ojeomneo",
  assetPrefix: "/ojeomneo",
  output: "standalone", // Docker 배포를 위한 standalone 빌드
};

export default nextConfig;
