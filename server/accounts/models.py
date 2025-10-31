"""
Custom User Model with email-based authentication.
"""
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from core.models import CoreModel
from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin, CoreModel):
    """
    Custom user model where email is the unique identifier
    for authentication instead of username.

    Inherits from:
        - AbstractBaseUser: Provides core authentication functionality
        - PermissionsMixin: Adds permissions and groups support
        - CoreModel: Provides created_at and updated_at timestamps

    Fields:
        email: User's email address (unique identifier)
        is_staff: Designates whether the user can log into admin site
        is_active: Designates whether this user account is active
    """
    email = models.EmailField(
        max_length=255,
        unique=True,
        help_text="User's email address"
    )
    is_staff = models.BooleanField(
        default=False,
        help_text="Designates whether the user can log into admin site"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Designates whether this user account is active"
    )

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    class Meta:
        verbose_name = 'user'
        verbose_name_plural = 'users'
        db_table = 'users'

    def __str__(self):
        """String representation of the user."""
        return self.email

    def get_full_name(self):
        """Return the email as the full name."""
        return self.email

    def get_short_name(self):
        """Return the email as the short name."""
        return self.email
