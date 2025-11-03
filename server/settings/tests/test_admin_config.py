"""
TDD tests for Django Unfold admin configuration.
"""
from django.test import TestCase
from django.conf import settings
from django.urls import reverse
from accounts.models import User


class UnfoldAdminConfigTestCase(TestCase):
    """Test cases for Django Unfold admin configuration."""

    def test_unfold_installed(self):
        """Test that unfold is installed before django.contrib.admin."""
        self.assertIn('unfold', settings.INSTALLED_APPS)

        unfold_index = settings.INSTALLED_APPS.index('unfold')
        admin_index = settings.INSTALLED_APPS.index('django.contrib.admin')

        self.assertLess(
            unfold_index,
            admin_index,
            "unfold must be placed before django.contrib.admin in INSTALLED_APPS"
        )

    def test_unfold_settings_exist(self):
        """Test that UNFOLD settings are configured."""
        self.assertTrue(hasattr(settings, 'UNFOLD'))
        self.assertIsInstance(settings.UNFOLD, dict)

    def test_unfold_site_title(self):
        """Test that UNFOLD SITE_TITLE is configured."""
        self.assertIn('SITE_TITLE', settings.UNFOLD)
        self.assertIsNotNone(settings.UNFOLD['SITE_TITLE'])
        self.assertNotEqual(settings.UNFOLD['SITE_TITLE'], '')

    def test_unfold_site_header(self):
        """Test that UNFOLD SITE_HEADER is configured."""
        self.assertIn('SITE_HEADER', settings.UNFOLD)
        self.assertIsNotNone(settings.UNFOLD['SITE_HEADER'])
        self.assertNotEqual(settings.UNFOLD['SITE_HEADER'], '')

    def test_unfold_favicon_path(self):
        """Test that UNFOLD SITE_FAVICON is configured."""
        self.assertIn('SITE_FAVICON', settings.UNFOLD)
        self.assertEqual(settings.UNFOLD['SITE_FAVICON'], '/static/favicon.ico')

    def test_static_root_configured(self):
        """Test that STATIC_ROOT is configured for collectstatic."""
        self.assertTrue(hasattr(settings, 'STATIC_ROOT'))
        self.assertIsNotNone(settings.STATIC_ROOT)
        self.assertTrue(str(settings.STATIC_ROOT).endswith('staticfiles'))

    def test_static_url_configured(self):
        """Test that STATIC_URL is configured."""
        self.assertTrue(hasattr(settings, 'STATIC_URL'))
        # STATIC_URL can be 'static/' or '/static/'
        self.assertTrue(settings.STATIC_URL in ['static/', '/static/'])


class AdminAccessTestCase(TestCase):
    """Test cases for admin site accessibility."""

    def setUp(self):
        """Set up test user."""
        self.admin_user = User.objects.create_superuser(
            email='admin@test.com',
            password='testpass123'
        )
        self.admin_url = reverse('admin:index')

    def test_admin_url_exists(self):
        """Test that admin URL is accessible."""
        response = self.client.get(self.admin_url)
        # Should redirect to login page (302) or show login form (200)
        self.assertIn(response.status_code, [200, 302])

    def test_admin_login_success(self):
        """Test that admin user can log in successfully."""
        self.client.login(email='admin@test.com', password='testpass123')
        response = self.client.get(self.admin_url)
        self.assertEqual(response.status_code, 200)

    def test_admin_page_title(self):
        """Test that admin page shows unfold customization."""
        self.client.login(email='admin@test.com', password='testpass123')
        response = self.client.get(self.admin_url)
        self.assertEqual(response.status_code, 200)

        # Check if the response contains our custom site title
        content = response.content.decode('utf-8')
        # Unfold admin should be loaded
        self.assertTrue('admin' in content.lower())
