"""
Core base model with timestamp fields.
All models should inherit from this base model.
"""
from django.db import models


class CoreModel(models.Model):
    """
    Abstract base model that provides created_at and updated_at timestamps.

    All models in the project should inherit from this model to ensure
    consistent timestamp tracking across the application.

    Fields:
        created_at: Timestamp when the record was created
        updated_at: Timestamp when the record was last updated
    """
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Timestamp when the record was created"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Timestamp when the record was last updated"
    )

    class Meta:
        abstract = True
        ordering = ['-created_at']
