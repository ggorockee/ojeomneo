"""
TDD tests for custom User model.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.db import IntegrityError


User = get_user_model()


class UserModelTestCase(TestCase):
    """Test cases for the custom User model."""

    def setUp(self):
        """Set up test data."""
        self.email = "test@example.com"
        self.password = "testpass123"

    def test_create_user_with_email(self):
        """Test creating a user with email is successful."""
        user = User.objects.create_user(
            email=self.email,
            password=self.password
        )
        self.assertEqual(user.email, self.email)
        self.assertTrue(user.check_password(self.password))
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
        self.assertFalse(user.is_superuser)

    def test_create_user_without_email_raises_error(self):
        """Test creating a user without email raises ValueError."""
        with self.assertRaises(ValueError):
            User.objects.create_user(email='', password=self.password)

    def test_create_superuser(self):
        """Test creating a superuser."""
        admin_user = User.objects.create_superuser(
            email='admin@example.com',
            password='admin123'
        )
        self.assertTrue(admin_user.is_active)
        self.assertTrue(admin_user.is_staff)
        self.assertTrue(admin_user.is_superuser)

    def test_create_superuser_without_is_staff_raises_error(self):
        """Test creating superuser with is_staff=False raises ValueError."""
        with self.assertRaises(ValueError):
            User.objects.create_superuser(
                email='admin@example.com',
                password='admin123',
                is_staff=False
            )

    def test_create_superuser_without_is_superuser_raises_error(self):
        """Test creating superuser with is_superuser=False raises ValueError."""
        with self.assertRaises(ValueError):
            User.objects.create_superuser(
                email='admin@example.com',
                password='admin123',
                is_superuser=False
            )

    def test_email_normalized(self):
        """Test email is normalized when creating user."""
        email = 'test@EXAMPLE.COM'
        user = User.objects.create_user(email=email, password=self.password)
        self.assertEqual(user.email, email.lower())

    def test_email_unique(self):
        """Test that email must be unique."""
        User.objects.create_user(email=self.email, password=self.password)
        with self.assertRaises(IntegrityError):
            User.objects.create_user(email=self.email, password='different123')

    def test_user_string_representation(self):
        """Test the string representation of user."""
        user = User.objects.create_user(email=self.email, password=self.password)
        self.assertEqual(str(user), self.email)

    def test_user_has_timestamps(self):
        """Test that user model has created_at and updated_at fields."""
        user = User.objects.create_user(email=self.email, password=self.password)
        self.assertIsNotNone(user.created_at)
        self.assertIsNotNone(user.updated_at)
        self.assertTrue(hasattr(user, 'created_at'))
        self.assertTrue(hasattr(user, 'updated_at'))

    def test_username_field_is_email(self):
        """Test that USERNAME_FIELD is set to email."""
        self.assertEqual(User.USERNAME_FIELD, 'email')

    def test_user_has_no_username_field(self):
        """Test that user model does not have username field."""
        user = User.objects.create_user(email=self.email, password=self.password)
        self.assertFalse(hasattr(user, 'username'))


class UserManagerTestCase(TestCase):
    """Test cases for custom UserManager."""

    def test_create_user_returns_user_instance(self):
        """Test that create_user returns a User instance."""
        user = User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )
        self.assertIsInstance(user, User)

    def test_create_superuser_returns_user_instance(self):
        """Test that create_superuser returns a User instance."""
        admin = User.objects.create_superuser(
            email='admin@example.com',
            password='admin123'
        )
        self.assertIsInstance(admin, User)

    def test_manager_accessible_through_objects(self):
        """Test that custom manager is accessible through User.objects."""
        self.assertTrue(hasattr(User, 'objects'))
        self.assertIsNotNone(User.objects)
