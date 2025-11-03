"""
TDD tests for async database utility functions.
"""
from django.test import TestCase
from unittest.mock import patch
from core.utils.database import check_database_connection_async


class DatabaseAsyncUtilityTestCase(TestCase):
    """Test cases for async database utility functions."""

    async def test_check_database_connection_async_returns_tuple(self):
        """Test that check_database_connection_async returns a tuple."""
        result = await check_database_connection_async()
        self.assertIsInstance(result, tuple, "Result should be a tuple")
        self.assertEqual(len(result), 2, "Result should have 2 elements")

    async def test_check_database_connection_async_success(self):
        """Test successful async database connection check."""
        is_connected, message = await check_database_connection_async()

        self.assertIsInstance(is_connected, bool, "First element should be boolean")
        self.assertIsInstance(message, str, "Second element should be string")
        self.assertTrue(is_connected, "Database should be connected in test environment")
        self.assertIn('successful', message.lower(), "Message should indicate success")

    @patch('core.utils.database.check_database_connection')
    async def test_check_database_connection_async_failure(self, mock_connection):
        """Test async database connection check failure."""
        # Mock connection failure
        mock_connection.return_value = (False, "Connection refused")

        is_connected, message = await check_database_connection_async()

        self.assertFalse(is_connected, "Connection should fail")
        self.assertIn('refused', message.lower(), "Message should indicate failure")

    async def test_async_wrapper_works(self):
        """Test that async wrapper properly wraps sync function."""
        # This test verifies that the async wrapper correctly calls
        # the synchronous version using sync_to_async
        result = await check_database_connection_async()
        self.assertIsNotNone(result, "Async wrapper should return result")
        self.assertEqual(len(result), 2, "Result should maintain tuple structure")
