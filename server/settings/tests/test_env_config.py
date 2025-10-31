"""
TDD tests for environment variable configuration.
"""
import os
from django.test import TestCase
from django.conf import settings


class EnvironmentConfigTestCase(TestCase):
    """Test cases for environment variable loading and configuration."""

    def test_secret_key_loaded_from_env(self):
        """Test that SECRET_KEY is loaded from environment variables."""
        # SECRET_KEY should be set (either from .env or default)
        self.assertIsNotNone(settings.SECRET_KEY)
        self.assertNotEqual(settings.SECRET_KEY, '')
        self.assertIsInstance(settings.SECRET_KEY, str)

    def test_debug_setting_loaded(self):
        """Test that DEBUG setting is loaded properly."""
        # DEBUG should be a boolean
        self.assertIsInstance(settings.DEBUG, bool)

    def test_database_config_loaded(self):
        """Test that database configuration is loaded from environment."""
        db_config = settings.DATABASES['default']

        # Check that all required database fields exist
        self.assertIn('ENGINE', db_config)
        self.assertIn('NAME', db_config)
        self.assertIn('USER', db_config)
        self.assertIn('PASSWORD', db_config)
        self.assertIn('HOST', db_config)
        self.assertIn('PORT', db_config)

        # Check that values are not empty
        self.assertNotEqual(db_config['ENGINE'], '')
        self.assertNotEqual(db_config['NAME'], '')
        self.assertNotEqual(db_config['USER'], '')
        self.assertNotEqual(db_config['HOST'], '')
        self.assertNotEqual(db_config['PORT'], '')

    def test_database_engine_is_postgresql(self):
        """Test that database engine is PostgreSQL."""
        db_engine = settings.DATABASES['default']['ENGINE']
        self.assertEqual(db_engine, 'django.db.backends.postgresql')

    def test_database_values_match_expected(self):
        """Test that database values match expected configuration."""
        db_config = settings.DATABASES['default']

        # Note: Django automatically prefixes test DB names with 'test_'
        # So we check for the base name or test name
        db_name = db_config['NAME']
        self.assertTrue(
            db_name == 'test' or db_name.startswith('test_'),
            f"Database name should be 'test' or start with 'test_', got: {db_name}"
        )

        self.assertEqual(db_config['USER'], 'test')
        self.assertEqual(db_config['HOST'], 'localhost')
        self.assertEqual(db_config['PORT'], '5432')

    def test_env_file_location(self):
        """Test that .env file is in the correct location."""
        from pathlib import Path
        env_path = settings.BASE_DIR / '.env'

        # .env file should exist during development
        self.assertTrue(env_path.exists(), f".env file not found at {env_path}")

    def test_dotenv_package_available(self):
        """Test that python-dotenv package is available."""
        try:
            import dotenv
            self.assertTrue(True, "python-dotenv is installed")
        except ImportError:
            self.fail("python-dotenv package is not installed")

    def test_os_getenv_fallback_mechanism(self):
        """Test that environment variables have fallback values."""
        # Even if .env doesn't exist, settings should have defaults
        self.assertIsNotNone(settings.SECRET_KEY)
        self.assertIsNotNone(settings.DATABASES['default']['ENGINE'])
        self.assertIsNotNone(settings.DATABASES['default']['NAME'])

    def test_allowed_hosts_configuration(self):
        """Test that ALLOWED_HOSTS is properly configured."""
        # ALLOWED_HOSTS should be a list
        self.assertIsInstance(settings.ALLOWED_HOSTS, list)

        # In development, it can be empty or contain values
        # Just verify it's a list type
        self.assertTrue(isinstance(settings.ALLOWED_HOSTS, list))

    def test_environment_variables_not_hardcoded(self):
        """Test that sensitive data is loaded from env, not hardcoded."""
        # Check that SECRET_KEY comes from environment
        # by verifying it matches what's in .env
        expected_key = os.getenv('SECRET_KEY')
        if expected_key:
            self.assertEqual(settings.SECRET_KEY, expected_key)

        # Database password should come from environment
        expected_db_password = os.getenv('DB_PASSWORD')
        if expected_db_password:
            self.assertEqual(
                settings.DATABASES['default']['PASSWORD'],
                expected_db_password
            )
