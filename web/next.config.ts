import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  basePath: "/ojeomneo",
  assetPrefix: "/ojeomneo",
  output: "standalone", // Docker 배포를 위한 standalone 빌드
  images: {
    unoptimized: true, // standalone 모드에서 이미지 최적화 비활성화
  },
};

export default nextConfig;
