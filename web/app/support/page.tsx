"use client";

import Link from "next/link";
import Image from "next/image";
import { useState } from "react";

export default function Support() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    device: "",
    appVersion: "",
    subject: "",
    message: "",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<"idle" | "success" | "error">("idle");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setSubmitStatus("idle");

    try {
      // 이메일로 전송 (mailto 링크 사용)
      const subject = encodeURIComponent(`[오점너 문의] ${formData.subject}`);
      const body = encodeURIComponent(`
이름: ${formData.name}
이메일: ${formData.email}
기기: ${formData.device}
앱 버전: ${formData.appVersion}

문의 내용:
${formData.message}
      `);

      window.location.href = `mailto:woohaen88@gmail.com?subject=${subject}&body=${body}`;

      setSubmitStatus("success");
      // 폼 초기화
      setFormData({
        name: "",
        email: "",
        device: "",
        appVersion: "",
        subject: "",
        message: "",
      });
    } catch (error) {
      console.error("Form submission error:", error);
      setSubmitStatus("error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-sm shadow-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <Link href="/" className="flex items-center space-x-3">
              <Image
                src="/assets/images/logo.png"
                alt="오점너 로고"
                width={40}
                height={40}
                className="w-10 h-10"
              />
              <h1 className="text-2xl font-bold text-gray-900">오점너</h1>
            </Link>
            <Link href="/" className="text-green-600 hover:text-green-700 font-medium">
              홈으로 돌아가기
            </Link>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-white rounded-2xl shadow-lg p-8 md:p-12">
          <h1 className="text-4xl font-bold text-gray-900 mb-8">고객 지원</h1>

          <div className="prose prose-lg max-w-none">
            <p className="text-gray-600 mb-8">
              오점너를 이용해 주셔서 감사합니다. 앱 사용 중 문제가 발생하거나 궁금한 사항이 있으시면 아래 정보를 참고해 주세요.
            </p>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">앱 정보</h2>
              <div className="bg-blue-50 p-6 rounded-xl">
                <ul className="text-gray-700 space-y-2">
                  <li>• <strong>앱 이름</strong>: 오점너</li>
                  <li>• <strong>개발자</strong>: WooHyeon Kim</li>
                  <li>• <strong>버전</strong>: 1.0.0</li>
                  <li>• <strong>설명</strong>: 스케치 기반 메뉴 추천 앱</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">자주 묻는 질문</h2>

              <div className="space-y-4">
                <div className="bg-gray-50 p-6 rounded-xl">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">Q. 오점너는 어떤 앱인가요?</h3>
                  <p className="text-gray-700">
                    오점너는 스케치나 사진을 업로드하면 AI가 메뉴를 추천해주는 앱입니다.
                    먹고 싶은 음식을 스케치하거나 사진으로 찍어 업로드하면, AI가 분석하여 비슷한 메뉴를 추천해드립니다.
                  </p>
                </div>

                <div className="bg-gray-50 p-6 rounded-xl">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">Q. 회원가입이 필요한가요?</h3>
                  <p className="text-gray-700">
                    비회원으로도 서비스를 이용할 수 있습니다. 다만, 회원가입을 하시면 추천 기록을 저장하고
                    언제든지 다시 확인할 수 있습니다.
                  </p>
                </div>

                <div className="bg-gray-50 p-6 rounded-xl">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">Q. 개인정보는 안전한가요?</h3>
                  <p className="text-gray-700">
                    네, 오점너는 개인정보 보호를 최우선으로 생각합니다.
                    비회원 데이터는 7일 후 자동 삭제되며, 모든 데이터는 암호화되어 안전하게 보관됩니다.
                    자세한 내용은 <Link href="/privacy" className="text-blue-600 hover:underline">개인정보처리방침</Link>을 참고해 주세요.
                  </p>
                </div>

                <div className="bg-gray-50 p-6 rounded-xl">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">Q. 계정을 삭제하고 싶어요</h3>
                  <p className="text-gray-700 mb-2">
                    계정 삭제는 다음 두 가지 방법으로 가능합니다:
                  </p>
                  <ul className="text-gray-700 space-y-1 ml-4">
                    <li>1. 앱 내 프로필 {'>'} 설정 {'>'} 계정 삭제</li>
                    <li>2. 이메일(<a href="mailto:woohaen88@gmail.com" className="text-blue-600 hover:underline">woohaen88@gmail.com</a>)로 삭제 요청</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">문의하기</h2>
              <div className="bg-white border-2 border-green-200 rounded-xl p-6">
                <p className="text-gray-700 mb-6">
                  위에서 답변을 찾지 못하셨거나 추가 문의사항이 있으시면 아래 양식을 작성해 주세요.
                </p>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="grid md:grid-cols-2 gap-4">
                    <div>
                      <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-1">
                        이름 <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="text"
                        id="name"
                        name="name"
                        required
                        value={formData.name}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="홍길동"
                      />
                    </div>

                    <div>
                      <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                        이메일 <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="email"
                        id="email"
                        name="email"
                        required
                        value={formData.email}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="example@email.com"
                      />
                    </div>
                  </div>

                  <div className="grid md:grid-cols-2 gap-4">
                    <div>
                      <label htmlFor="device" className="block text-sm font-medium text-gray-700 mb-1">
                        사용 기기
                      </label>
                      <select
                        id="device"
                        name="device"
                        value={formData.device}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                      >
                        <option value="">선택해 주세요</option>
                        <option value="iPhone">iPhone</option>
                        <option value="iPad">iPad</option>
                        <option value="Android">Android</option>
                        <option value="기타">기타</option>
                      </select>
                    </div>

                    <div>
                      <label htmlFor="appVersion" className="block text-sm font-medium text-gray-700 mb-1">
                        앱 버전
                      </label>
                      <input
                        type="text"
                        id="appVersion"
                        name="appVersion"
                        value={formData.appVersion}
                        onChange={handleChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        placeholder="1.0.0"
                      />
                    </div>
                  </div>

                  <div>
                    <label htmlFor="subject" className="block text-sm font-medium text-gray-700 mb-1">
                      문의 제목 <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      id="subject"
                      name="subject"
                      required
                      value={formData.subject}
                      onChange={handleChange}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                      placeholder="문의 제목을 입력해 주세요"
                    />
                  </div>

                  <div>
                    <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-1">
                      문의 내용 <span className="text-red-500">*</span>
                    </label>
                    <textarea
                      id="message"
                      name="message"
                      required
                      value={formData.message}
                      onChange={handleChange}
                      rows={6}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent resize-none"
                      placeholder="문의 내용을 상세히 작성해 주세요"
                    />
                  </div>

                  {submitStatus === "success" && (
                    <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg">
                      문의가 전송되었습니다. 빠른 시일 내에 답변드리겠습니다.
                    </div>
                  )}

                  {submitStatus === "error" && (
                    <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
                      문의 전송 중 오류가 발생했습니다. 이메일(woohaen88@gmail.com)로 직접 연락해 주세요.
                    </div>
                  )}

                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="w-full bg-green-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
                  >
                    {isSubmitting ? "전송 중..." : "문의하기"}
                  </button>

                  <p className="text-sm text-gray-500 text-center">
                    또는 <a href="mailto:woohaen88@gmail.com" className="text-green-600 hover:underline">woohaen88@gmail.com</a>으로 직접 이메일을 보내실 수 있습니다.
                  </p>
                </form>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">관련 링크</h2>
              <div className="grid md:grid-cols-2 gap-4">
                <Link href="/privacy" className="bg-gray-50 p-6 rounded-xl hover:bg-gray-100 transition-colors">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">개인정보처리방침</h3>
                  <p className="text-gray-600">개인정보 수집 및 이용에 대한 상세 안내</p>
                </Link>
                <a href="https://api.woohalabs.com/ojeomneo/v1" className="bg-gray-50 p-6 rounded-xl hover:bg-gray-100 transition-colors">
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">API 문서</h3>
                  <p className="text-gray-600">개발자를 위한 API 정보</p>
                </a>
              </div>
            </section>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="flex items-center justify-center space-x-3 mb-4">
            <Image
              src="/assets/images/logo.png"
              alt="오점너 로고"
              width={32}
              height={32}
              className="w-8 h-8"
            />
            <h3 className="text-xl font-bold">오점너</h3>
          </div>
          <p className="text-gray-400">&copy; 2024 오점너. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
}
