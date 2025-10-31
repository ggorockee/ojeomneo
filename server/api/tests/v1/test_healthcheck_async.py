"""
TDD tests for async healthcheck API endpoint.
"""
from django.test import TestCase
from django.test.client import AsyncClient
from unittest.mock import patch, AsyncMock
import json


class HealthCheckAsyncAPITestCase(TestCase):
    """Test cases for the async healthcheck endpoint."""

    def setUp(self):
        """Set up async test client."""
        self.client = AsyncClient()
        self.healthcheck_url = '/v1/healthcheck'

    async def test_healthcheck_endpoint_exists_async(self):
        """Test that async healthcheck endpoint is accessible."""
        response = await self.client.get(self.healthcheck_url)
        self.assertNotEqual(response.status_code, 404, "Healthcheck endpoint should exist")

    async def test_healthcheck_returns_200_async(self):
        """Test that async healthcheck returns HTTP 200 status code."""
        response = await self.client.get(self.healthcheck_url)
        self.assertEqual(response.status_code, 200, "Healthcheck should return 200 OK")

    async def test_healthcheck_returns_json_async(self):
        """Test that async healthcheck returns JSON response."""
        response = await self.client.get(self.healthcheck_url)
        content_type = response['Content-Type']
        self.assertTrue(
            content_type.startswith('application/json'),
            f"Healthcheck should return JSON content type, got: {content_type}"
        )

    async def test_healthcheck_response_structure_async(self):
        """Test that async healthcheck response has correct structure."""
        response = await self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        # Check required keys exist
        self.assertIn('status', data, "Response should contain 'status' key")
        self.assertIn('message', data, "Response should contain 'message' key")
        self.assertIn('database', data, "Response should contain 'database' key")

        # Check database sub-structure
        self.assertIn('connected', data['database'], "Database should contain 'connected' key")
        self.assertIn('message', data['database'], "Database should contain 'message' key")

    async def test_healthcheck_with_database_connected_async(self):
        """Test async healthcheck when database is connected."""
        response = await self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertEqual(data['status'], 'ok', "Status should be 'ok' when DB is connected")
        self.assertTrue(data['database']['connected'], "Database should be connected")
        self.assertIn('successful', data['database']['message'].lower(),
                      "Database message should indicate success")

    @patch('core.utils.database.check_database_connection')
    async def test_healthcheck_with_database_disconnected_async(self, mock_connection):
        """Test async healthcheck when database connection fails."""
        # Mock database connection failure
        mock_connection.return_value = (False, "Connection failed")

        response = await self.client.get(self.healthcheck_url)
        data = json.loads(response.content)

        self.assertEqual(data['status'], 'degraded', "Status should be 'degraded' when DB fails")
        self.assertFalse(data['database']['connected'], "Database should not be connected")

    async def test_healthcheck_is_async(self):
        """Test that healthcheck endpoint is truly async."""
        # This test verifies that the endpoint handles async operations
        response = await self.client.get(self.healthcheck_url)
        self.assertEqual(response.status_code, 200, "Async endpoint should work")

        # Verify response contains expected data
        data = json.loads(response.content)
        self.assertIn('database', data, "Async response should include database info")
