import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "오점너 - 스케치로 찾는 맛집 메뉴",
  description: "오점너는 음식 사진이나 간단한 스케치로 맛집의 메뉴를 추천해주는 AI 기반 앱입니다. 메뉴 이름이 기억나지 않아도 쉽게 찾을 수 있어요.",
  keywords: ["메뉴 추천", "AI", "음식", "스케치", "맛집", "메뉴 찾기", "오점너"],
  authors: [{ name: "오점너" }],
  creator: "오점너",
  publisher: "오점너",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL('https://ojeomneo.com'),
  alternates: {
    canonical: '/',
  },
  verification: {
    google: 'your-google-verification-code',
  },
  openGraph: {
    title: "오점너 - 스케치로 찾는 맛집 메뉴",
    description: "오점너는 음식 사진이나 간단한 스케치로 맛집의 메뉴를 추천해주는 AI 기반 앱입니다.",
    url: 'https://ojeomneo.com',
    siteName: '오점너',
    images: [
      {
        url: 'https://ojeomneo.com/assets/images/logo.png',
        width: 1200,
        height: 630,
        alt: '오점너 앱 화면 - 스케치로 찾는 맛집 메뉴',
        type: 'image/png',
      },
    ],
    locale: 'ko_KR',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: "오점너 - 스케치로 찾는 맛집 메뉴",
    description: "오점너는 음식 사진이나 간단한 스케치로 맛집의 메뉴를 추천해주는 AI 기반 앱입니다.",
    images: ['https://ojeomneo.com/assets/images/logo.png'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  icons: {
    icon: '/favicon.png?v=2',
    shortcut: '/favicon.png?v=2',
    apple: '/favicon.png?v=2',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
