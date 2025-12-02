"""
기존 DB 세션 테이블 정리 명령어

Redis로 세션 저장소를 마이그레이션한 후,
더 이상 사용하지 않는 django_session 테이블의 데이터를 정리합니다.
"""

from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = "기존 django_session 테이블의 데이터를 정리합니다 (Redis 마이그레이션 후 사용)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="실제로 삭제하지 않고 삭제될 레코드 수만 출력합니다",
        )
        parser.add_argument(
            "--drop-table",
            action="store_true",
            help="테이블 자체를 삭제합니다 (주의: 되돌릴 수 없음)",
        )

    def handle(self, *args, **options):
        dry_run = options["dry_run"]
        drop_table = options["drop_table"]

        with connection.cursor() as cursor:
            # 테이블 존재 여부 확인
            cursor.execute(
                """
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_name = 'django_session'
                )
            """
            )
            table_exists = cursor.fetchone()[0]

            if not table_exists:
                self.stdout.write(self.style.SUCCESS("django_session 테이블이 존재하지 않습니다."))
                return

            # 현재 레코드 수 확인
            cursor.execute("SELECT COUNT(*) FROM django_session")
            count = cursor.fetchone()[0]

            if dry_run:
                self.stdout.write(f"django_session 테이블에 {count}개의 레코드가 있습니다.")
                if drop_table:
                    self.stdout.write("--drop-table 옵션: 테이블이 삭제됩니다.")
                return

            if drop_table:
                cursor.execute("DROP TABLE IF EXISTS django_session CASCADE")
                self.stdout.write(self.style.SUCCESS(f"django_session 테이블을 삭제했습니다. (기존 {count}개 레코드)"))
            else:
                cursor.execute("TRUNCATE TABLE django_session")
                self.stdout.write(self.style.SUCCESS(f"django_session 테이블에서 {count}개의 레코드를 삭제했습니다."))

        self.stdout.write(self.style.SUCCESS("세션 정리가 완료되었습니다. 이제 세션은 Redis에 저장됩니다."))
