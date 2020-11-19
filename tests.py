import json

from utilities.factories import *

from locust import HttpUser, task, between


class MyExampleAPITest(HttpUser):
    wait_time = between(1,3)

    # The @task decorator allows you to weight tests against one another,
    # so that you can run Test1 n times more than Test2, etc.
    @task(2)
    def api_post_test(self):
        url = "https://some-api-endpoint.com/endpoint"
        headers = {'content-type': 'application/json'}
        data = example_factory()

        response = self.client.post(url, data=json.dumps(data), headers=headers)

        assert response.status_code == 200
