# Ojeomneo Web

오점너(Ojeomneo) 프로젝트의 웹 애플리케이션입니다.

This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Tech Stack

- **Framework**: Next.js 15.5.7 with Turbopack
- **React**: 19.1.0
- **Styling**: Tailwind CSS 4.0
- **TypeScript**: 5.x

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Build

프로덕션 빌드를 생성하려면:

```bash
npm run build
```

빌드된 애플리케이션을 실행하려면:

```bash
npm start
```

## CI/CD

이 프로젝트는 GitHub Actions를 통해 자동 배포됩니다:
- `main` 브랜치에 푸시 시 자동으로 Docker 이미지 빌드
- ArgoCD를 통한 Kubernetes 배포

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
