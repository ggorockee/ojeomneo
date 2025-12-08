'use client';

import Image from "next/image";
import Link from "next/link";
import { useState, useRef, useEffect, useCallback } from "react";

export default function Home() {
  const [isDragging, setIsDragging] = useState(false);
  const [startX, setStartX] = useState(0);
  const [scrollLeft, setScrollLeft] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
  const sliderRef = useRef<HTMLDivElement>(null);
  const animationRef = useRef<number | null>(null);

  const handleMouseDown = (e: React.MouseEvent) => {
    if (!sliderRef.current) return;
    setIsDragging(true);
    setStartX(e.pageX - sliderRef.current.offsetLeft);
    setScrollLeft(sliderRef.current.scrollLeft);
    // 드래그 시작 시 애니메이션 정지
    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current);
    }
  };

  const handleMouseLeave = () => {
    setIsDragging(false);
    setIsHovered(false);
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging || !sliderRef.current) return;
    e.preventDefault();
    const x = e.pageX - sliderRef.current.offsetLeft;
    const walk = (x - startX) * 2;
    sliderRef.current.scrollLeft = scrollLeft - walk;
  };

  const handleMouseEnter = () => {
    setIsHovered(true);
    // 호버 시 애니메이션 정지
    if (animationRef.current) {
      cancelAnimationFrame(animationRef.current);
    }
  };


  const startAutoScroll = useCallback(() => {
    if (!sliderRef.current) return;
    
    const scroll = () => {
      if (!sliderRef.current || isDragging || isHovered) return;
      
      const maxScroll = sliderRef.current.scrollWidth - sliderRef.current.clientWidth;
      const currentScroll = sliderRef.current.scrollLeft;
      
      if (currentScroll >= maxScroll) {
        // 끝에 도달하면 처음으로 리셋
        sliderRef.current.scrollLeft = 0;
      } else {
        // 천천히 스크롤 (1.5배 빠르게)
        sliderRef.current.scrollLeft += 1.5;
      }
      
      animationRef.current = requestAnimationFrame(scroll);
    };
    
    animationRef.current = requestAnimationFrame(scroll);
  }, [isDragging, isHovered]);

  useEffect(() => {
    if (!isDragging && !isHovered) {
      startAutoScroll();
    }
    
    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, [isDragging, isHovered, startAutoScroll]);

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <Image
                src="/assets/images/logo.png"
                alt="오점너 로고"
                width={40}
                height={40}
                className="w-8 h-8 sm:w-10 sm:h-10"
              />
              <h1 className="text-xl sm:text-2xl font-bold text-gray-900">오점너</h1>
            </div>
            <nav className="hidden md:flex space-x-8">
              <a href="#features" className="text-gray-600 hover:text-green-600 transition-colors">주요 기능</a>
              <a href="#how-to-use" className="text-gray-600 hover:text-green-600 transition-colors">사용법</a>
              <a href="#screenshots" className="text-gray-600 hover:text-green-600 transition-colors">앱 화면</a>
              <Link href="/privacy" className="text-gray-600 hover:text-green-600 transition-colors">개인정보처리방침</Link>
            </nav>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative py-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center">
            <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-bold text-gray-900 mb-6 animate-fade-in-up">
              오점너
              <span className="block text-2xl sm:text-3xl md:text-4xl gradient-text mt-2">
                스케치로 찾는 맛집 메뉴
              </span>
            </h1>
            <p className="text-lg sm:text-xl text-gray-600 mb-8 max-w-3xl mx-auto leading-relaxed px-4">
              메뉴 이름이 기억나지 않아 고민하셨나요?<br />
              오점너는 음식 사진이나 간단한 스케치로<br />
              맛집의 메뉴를 추천해주는 AI 기반 앱입니다.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center items-center">
              <div className="flex gap-3 sm:hidden">
                <a href="#" target="_blank" rel="noopener noreferrer" className="inline-block">
                  <Image
                    src="/assets/images/google-play-badge.png"
                    alt="Google Play에서 다운로드"
                    width={200}
                    height={60}
                    className="h-10 w-auto hover:opacity-80 transition-opacity"
                  />
                </a>
                <a href="#" target="_blank" rel="noopener noreferrer" className="inline-block">
                  <Image
                    src="/assets/images/app-store-badge.png"
                    alt="App Store에서 다운로드"
                    width={200}
                    height={60}
                    className="h-10 w-auto hover:opacity-80 transition-opacity"
                  />
                </a>
              </div>
              <div className="hidden sm:flex gap-4 items-center">
                <a href="#" target="_blank" rel="noopener noreferrer" className="inline-block">
                  <Image
                    src="/assets/images/google-play-badge.png"
                    alt="Google Play에서 다운로드"
                    width={200}
                    height={60}
                    className="h-14 w-auto hover:opacity-80 transition-opacity"
                  />
                </a>
                <a href="#" target="_blank" rel="noopener noreferrer" className="inline-block">
                  <Image
                    src="/assets/images/app-store-badge.png"
                    alt="App Store에서 다운로드"
                    width={200}
                    height={60}
                    className="h-14 w-auto hover:opacity-80 transition-opacity"
                  />
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">주요 기능</h2>
            <p className="text-lg sm:text-xl text-gray-600">오점너의 핵심 기능들을 확인해보세요</p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 animate-fade-in-up">
            <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-200 card-hover text-center">
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center mb-6 mx-auto">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">스케치로 메뉴 검색</h3>
              <p className="text-gray-600">음식 사진을 찍거나 간단한 스케치만으로 원하는 메뉴를 찾을 수 있습니다.</p>
            </div>

            <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-200 card-hover text-center">
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center mb-6 mx-auto">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">AI 기반 메뉴 추천</h3>
              <p className="text-gray-600">인공지능이 스케치를 분석하여 가장 비슷한 메뉴를 추천해드립니다.</p>
            </div>

            <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-200 card-hover text-center">
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center mb-6 mx-auto">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">빠른 결과 확인</h3>
              <p className="text-gray-600">몇 초 안에 AI가 분석한 메뉴 추천 결과를 확인할 수 있습니다.</p>
            </div>

            <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-200 card-hover text-center">
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center mb-6 mx-auto">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">메뉴 정보 제공</h3>
              <p className="text-gray-600">추천된 메뉴의 이름과 상세 정보를 한눈에 확인할 수 있습니다.</p>
            </div>

            <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-200 card-hover text-center">
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center mb-6 mx-auto">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">회원/비회원 모두 사용</h3>
              <p className="text-gray-600">비회원은 7일간, 회원은 무제한으로 서비스를 이용할 수 있습니다.</p>
            </div>

            <div className="bg-white p-6 sm:p-8 rounded-2xl border border-gray-200 card-hover text-center">
              <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center mb-6 mx-auto">
                <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">안전한 데이터 보호</h3>
              <p className="text-gray-600">스케치 이미지는 암호화되어 안전하게 처리되며, 비회원 데이터는 7일 후 자동 삭제됩니다.</p>
            </div>
          </div>
        </div>
      </section>

      {/* How to Use Section */}
      <section id="how-to-use" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">이렇게 사용해요</h2>
            <p className="text-lg sm:text-xl text-gray-600">간단한 3단계로 메뉴를 찾아보세요</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 animate-fade-in-up">
            <div className="text-center">
              <div className="w-16 h-16 bg-green-600 text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6">1</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-4">사진 촬영 또는 스케치</h3>
              <p className="text-gray-600">음식 사진을 찍거나 화면에 간단하게 스케치를 그려주세요.</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-green-600 text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6">2</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-4">AI 분석 대기</h3>
              <p className="text-gray-600">인공지능이 스케치나 사진을 분석하여 메뉴를 찾습니다.</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-green-600 text-white rounded-full flex items-center justify-center text-2xl font-bold mx-auto mb-6">3</div>
              <h3 className="text-xl font-semibold text-gray-900 mb-4">메뉴 확인</h3>
              <p className="text-gray-600">추천된 메뉴 목록을 확인하고 원하는 메뉴를 선택하세요.</p>
            </div>
          </div>
        </div>
      </section>

      {/* Screenshots Section */}
      <section id="screenshots" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold text-gray-900 mb-4">앱 화면 미리보기</h2>
            <p className="text-lg sm:text-xl text-gray-600">오점너의 실제 사용 화면을 확인해보세요</p>
          </div>

          <div className="relative overflow-hidden">
            <div 
              ref={sliderRef}
              className="flex overflow-x-auto scrollbar-hide cursor-grab active:cursor-grabbing"
              onMouseDown={handleMouseDown}
              onMouseLeave={handleMouseLeave}
              onMouseUp={handleMouseUp}
              onMouseMove={handleMouseMove}
              onMouseEnter={handleMouseEnter}
              style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}
            >
              <div className="flex space-x-8 min-w-max">
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-1.png"
                    alt="오점너 앱 화면 1"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-2.png"
                    alt="오점너 앱 화면 2"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-3.png"
                    alt="오점너 앱 화면 3"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-4.png"
                    alt="오점너 앱 화면 4"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-5.png"
                    alt="오점너 앱 화면 5"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                {/* 반복을 위해 다시 추가 */}
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-1.png"
                    alt="오점너 앱 화면 1"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-2.png"
                    alt="오점너 앱 화면 2"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-3.png"
                    alt="오점너 앱 화면 3"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-4.png"
                    alt="오점너 앱 화면 4"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
                <div className="bg-gray-100 rounded-2xl p-4 shadow-lg card-hover">
                  <Image
                    src="/assets/images/app-screenshot-5.png"
                    alt="오점너 앱 화면 5"
                    width={300}
                    height={600}
                    className="w-full h-auto rounded-xl"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid md:grid-cols-3 gap-8">
            <div>
              <div className="flex items-center space-x-3 mb-4">
                <Image
                  src="/assets/images/logo.png"
                  alt="오점너 로고"
                  width={40}
                  height={40}
                  className="w-8 h-8 sm:w-10 sm:h-10"
                />
                <h3 className="text-xl sm:text-2xl font-bold">오점너</h3>
              </div>
              <p className="text-gray-400">스케치로 찾는 맛집 메뉴, 가장 쉬운 방법</p>
            </div>
            
            <div>
              <h4 className="text-lg font-semibold mb-4">링크</h4>
              <ul className="space-y-2">
                <li><Link href="/privacy" className="text-gray-400 hover:text-green-400 transition-colors">개인정보처리방침</Link></li>
                <li><a href="#features" className="text-gray-400 hover:text-green-400 transition-colors">주요 기능</a></li>
                <li><a href="#how-to-use" className="text-gray-400 hover:text-green-400 transition-colors">사용법</a></li>
              </ul>
            </div>
            
            <div>
              <h4 className="text-lg font-semibold mb-4">문의</h4>
              <p className="text-gray-400">앱 관련 문의사항이 있으시면 언제든 연락주세요.</p>
            </div>
          </div>
          
          <div className="border-t border-gray-800 mt-8 pt-8 text-center">
            <p className="text-gray-400">&copy; 2024 오점너. All rights reserved.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}