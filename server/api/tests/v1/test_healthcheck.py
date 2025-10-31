"""
TDD tests for healthcheck API endpoint.
"""
from django.test import TestCase, Client
from django.db import connection
from unittest.mock import patch, MagicMock
import json


class HealthCheckAPITestCase(TestCase):
    """Test cases for the healthcheck endpoint."""

    def setUp(self):
        """Set up test client."""
        self.client = Client()
        self.healthcheck_url = '/v1/healthcheck'

    def test_healthcheck_endpoint_exists(self):
        """Test that healthcheck endpoint is accessible."""
        response = self.client.get(self.healthcheck_url)
        self.assertNotEqual(response.status_code, 404, "Healthcheck endpoint should exist")

    def test_healthcheck_returns_200(self):
        """Test that healthcheck returns HTTP 200 status code."""
        response = self.client.get(self.healthcheck_url)
        self.assertEqual(response.status_code, 200, "Healthcheck should return 200 OK")

    def test_healthcheck_returns_json(self):
        """Test that healthcheck returns JSON response."""
        response = self.client.get(self.healthcheck_url)
        content_type = response['Content-Type']
        self.assertTrue(
            content_type.startswith('application/json'),
            f"Healthcheck should return JSON content type, got: {content_type}"
        )

    def test_healthcheck_response_structure(self):
        """Test that healthcheck response has correct structure."""
        response = self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        # Check required keys exist
        self.assertIn('status', data, "Response should contain 'status' key")
        self.assertIn('message', data, "Response should contain 'message' key")
        self.assertIn('database', data, "Response should contain 'database' key")

        # Check database sub-structure
        self.assertIn('connected', data['database'], "Database should contain 'connected' key")
        self.assertIn('message', data['database'], "Database should contain 'message' key")

    def test_healthcheck_with_database_connected(self):
        """Test healthcheck when database is connected."""
        response = self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertEqual(data['status'], 'ok', "Status should be 'ok' when DB is connected")
        self.assertTrue(data['database']['connected'], "Database should be connected")
        self.assertIn('successful', data['database']['message'].lower(),
                      "Database message should indicate success")

    @patch('core.utils.database.connection')
    def test_healthcheck_with_database_disconnected(self, mock_connection):
        """Test healthcheck when database connection fails."""
        # Mock database connection failure
        mock_connection.ensure_connection.side_effect = Exception("Connection failed")

        response = self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertEqual(data['status'], 'degraded', "Status should be 'degraded' when DB fails")
        self.assertFalse(data['database']['connected'], "Database should not be connected")
        self.assertIn('failed', data['database']['message'].lower(),
                      "Database message should indicate failure")

    def test_healthcheck_message_not_empty(self):
        """Test that healthcheck message is not empty."""
        response = self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertNotEqual(data['message'], '', "Message should not be empty")
        self.assertTrue(len(data['message']) > 0, "Message should have content")

    def test_healthcheck_database_message_not_empty(self):
        """Test that database message is not empty."""
        response = self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertNotEqual(data['database']['message'], '', "Database message should not be empty")
        self.assertTrue(len(data['database']['message']) > 0, "Database message should have content")


class DatabaseUtilityTestCase(TestCase):
    """Test cases for database utility functions."""

    def test_check_database_connection_returns_tuple(self):
        """Test that check_database_connection returns a tuple."""
        from core.utils.database import check_database_connection

        result = check_database_connection()
        self.assertIsInstance(result, tuple, "Result should be a tuple")
        self.assertEqual(len(result), 2, "Result should have 2 elements")

    def test_check_database_connection_success(self):
        """Test successful database connection check."""
        from core.utils.database import check_database_connection

        is_connected, message = check_database_connection()

        self.assertIsInstance(is_connected, bool, "First element should be boolean")
        self.assertIsInstance(message, str, "Second element should be string")
        self.assertTrue(is_connected, "Database should be connected in test environment")
        self.assertIn('successful', message.lower(), "Message should indicate success")

    @patch('core.utils.database.connection')
    def test_check_database_connection_failure(self, mock_connection):
        """Test database connection check failure."""
        from core.utils.database import check_database_connection
        from django.db.utils import OperationalError

        # Mock connection failure
        mock_connection.ensure_connection.side_effect = OperationalError("Connection refused")

        is_connected, message = check_database_connection()

        self.assertFalse(is_connected, "Connection should fail")
        self.assertIn('failed', message.lower(), "Message should indicate failure")
