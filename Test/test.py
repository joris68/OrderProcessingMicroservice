import os
import json
import requests
import pytest


API_GATEWAY_URL = "https://rvwkeeis4m.execute-api.eu-central-1.amazonaws.com/developement/orders"

@pytest.mark.parametrize("payload, status_code, response_body", [
    ({"id": 1}, 201, "Order processed successfully."),
    ({}, 400, "Missing ID"),
    ({"id": -1}, 400, "Invalid order ID. Order ID must by bigger Zero"),
])



def test_api_orders(payload, status_code, response_body):
    """
    Test sending different payloads to the API and check the response status and body.
    """
    url = f"{API_GATEWAY_URL}/orders"  
    response = requests.post(url, json=payload)
    assert response.status_code == status_code
    assert response_body in response.text

