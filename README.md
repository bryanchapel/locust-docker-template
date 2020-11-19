# Overview
This project makes use of Locust, a Python based load testing framework. See [locust.io](https://locust.io/) for more info and docs. You can run Locust on it's own via the Locust CLI, but it really shines when you use Docker to spin up a set of distributed containers. This project can be further extended with [Kubernetes support as well](https://docs.locust.io/en/stable/running-locust-docker.html#running-a-distributed-load-test-on-kubernetes).

Tests are stored in `tests.py` as "User classes" broken up into individual test tasks.

Test payloads can be loaded from `utilities.factories`

# Setup
Setup is pretty straightforward when running outside of Docker:

`$ python3 -m venv .venv`

`$ source .venv/bin/activate`

`$ pip install -r requirements.txt`

With Docker it's even more straightforward:

`$ docker-compose up` 😀

# Running Locust
## Locust CLI
You can run the project on its own by simply running `locust <test-class-to-run>` (or just `locust` to run all tests at once), but this will max out cpu pretty quickly, which will limit the volume of load you can generate. Also note that in this scenario, Locust will look in the `locust.conf` file for any configuration specific settings that aren't appended to the command line, such as number of users to generate, user spawn rate, run time, whether to run headless vs the web interface, etc. In docker, these are pulled from either the `.env` file, or overridden as prepended arguments to `docker-compose`.

## Docker: Running Distributed
The other option is running with Docker: `docker-compose up --scale worker=4`. This allows you to make use of Locust's distributed runtime feature and generate significantly higher load volume. The command above will spin up 1 master container, and 4 worker containers that connect to the master to generate load. The master container will then spread out the generated users among the workers making more efficient use of system resources and allowing for higher req/s.

The above command will also run with whatever settings are in the project's `.env` file. The variables set in this file default to:
```
USERS=100
USER_SPAWN_RATE=10
RUN_TIME='-t 10m'
STOP_TIMEOUT=30
WORKERS_EXPECTED=4
HEADLESS=--headless
TEST_CLASSES=''
```

To change the runtime configuration of Locust running in Docker, you can either modify the properties in `.env`, or you can prepend variables to the `docker-compose` command to override the `.env` defaults. For example:

`$ EXPECT_WORKERS=8 USERS=500 USER_SPAWN_RATE=50 RUN_TIME='-t 60m' docker-compose up --scale worker=8`

**NOTE: the `EXPECT_WORKERS` variable should always be equal to the scaling of the worker containers. In this case both are 8.**

You can also set which test classes you're interested in running. This defaults to an empty string in `.env` which runs all of them. You can also pass a space delimited string and list out specific classes to run:

`$ TEST_CLASSES='MyExampleAPITest1 MyExampleAPITest2' EXPECT_WORKERS=4 USERS=50 USER_SPAWN_RATE=10 RUN_TIME='-t 5m' docker-compose up --scale worker=4`

## Headless vs Web UI
Locust comes with a handy web UI interface (accessed at http://localhost:8089 in the dockerized setup) that lets you specify users and spawn rates, as well as see real-time graphs of the testing performance. By default, the Docker setup uses the `--headless` flag. You can switch to the web UI by specifying `HEADLESS=''` as a parameter to the docker-compose command:

`$ HEADLESS='' EXPECT_WORKERS=4 USERS=50 USER_SPAWN_RATE=10 RUN_TIME='' docker-compose up --scale worker=4`

**NOTE: Because you're using the web UI to start/stop the test, you can't use the `RUN_TIME` flag. Otherwise you'll get an error stating "The --run-time argument can only be used together with --headless".**

In headless mode, you'll see a histogram of test performance output in the terminal/docker logs, and you'll get csv files of the test results in the `results` folder as well.

## Increasing Performance
The load testing classes typically extend from `HttpUser`, which uses the `requests` library under the hood. You can also use an alternate HTTP client that ships with Locust called `FastHttpUser`, which relies on the `geventhttpclient` library. From the [Locust docs](https://docs.locust.io/en/stable/increase-performance.html#increase-performance):

> Increase Locust’s performance with a faster HTTP client
>
> Locust’s default HTTP client uses python-requests. The reason for this is that requests is a very well-maintained python package, that provides a really nice API, that many python developers are familiar with. Therefore, in many cases, we recommend that you use the default HttpUser which uses requests. However, if you’re planning to run really large scale tests, Locust comes with an alternative HTTP client, FastHttpUser which uses geventhttpclient instead of requests. This client is significantly faster, and we’ve seen 5x-6x performance increases for making HTTP-requests. This does not necessarily mean that the number of users one can simulate per CPU core will automatically increase 5x-6x, since it also depends on what else the load testing script does. However, if your locust scripts are spending most of their CPU time in making HTTP-requests, you are likely to see significant performance gains.
>
> It is impossible to say what your particular hardware can handle, but in a best case scenario you should be able to do close to 5000 requests per second per core, instead of around 850 for the normal HttpUser (tested on a 2018 MacBook Pro i7 2.6GHz)

Example:
```
from locust import task
from locust.contrib.fasthttp import FastHttpUser

class MyUser(FastHttpUser):
    @task
    def index(self):
        response = self.client.get("/")
```