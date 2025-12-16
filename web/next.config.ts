import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // basePath와 assetPrefix는 Vercel Rewrites로 처리
  output: "standalone", // Docker 배포를 위한 standalone 빌드
};

export default nextConfig;
