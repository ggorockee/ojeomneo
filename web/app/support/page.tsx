import Link from "next/link";
import Image from "next/image";

export default function Support() {
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
              <div className="bg-green-50 p-6 rounded-xl">
                <p className="text-gray-700 mb-4">
                  위에서 답변을 찾지 못하셨거나 추가 문의사항이 있으시면 아래 이메일로 연락해 주세요.
                </p>
                <div className="text-gray-700">
                  <p><strong>이메일</strong>: <a href="mailto:woohaen88@gmail.com" className="text-blue-600 hover:underline">woohaen88@gmail.com</a></p>
                  <p className="mt-2 text-sm text-gray-600">
                    보내실 때는 다음 정보를 포함해 주시면 더 빠르게 도와드릴 수 있습니다:
                  </p>
                  <ul className="text-sm text-gray-600 space-y-1 mt-2 ml-4">
                    <li>• 사용 중인 기기 (iPhone/Android)</li>
                    <li>• 앱 버전</li>
                    <li>• 문제가 발생한 상황</li>
                    <li>• 스크린샷 (가능한 경우)</li>
                  </ul>
                </div>
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
