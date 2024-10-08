# Selenium Grid Docker

## Repository

This repository contains everything necessary to run Selenium Grid, the Nodes, and launch test suites.

### Repo Layout

- `resources/` contains the selenium-side-runner-image source, a test-site to run tests against, and the 'tests/' directory.
- `docker-compose/` contains the configs for the grid and the nodes.
- `tests/` tests.
  - Extra: Note the `x_n` dir. This contains a simple script setup to generating tests in mass. While slightly basic, it facilitates certain use cases rather simply. For example, if you have a user journey that requires discrete sessions be tested in parallel, the TEST_NO_STUB can be aligned with the test users username values. IE: testuser_0001. Tip: Give them all the same password for simplicity, or extend the script to generate unique passwords (see: gen_id) and output a list of credentials.
- `out/` where the test results are stored.

## Prerequisites

Aside from general knowledge that commands are executed in a terminal, not a lot.

> :penguin: This kit was developed on Linux, but in _theory_ docker is highly portable to Window and MacOS, and should work just as well.

### Running Selenium Grid & Tests

- [Docker](https://docs.docker.com/engine/install/)

### Creating/Maintaining New Tests

- [Chrome](https://support.google.com/chrome/answer/95346?hl=en&co=GENIE.Platform%3DDesktop)
- [Selenium IDE](https://chromewebstore.google.com/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd)

## Setup

### Build Selenium Side Runner Image

This is maintained here as there's potential for an amount of modification, depending what you're doing. To build it, run:

```
cd resources/selenium-side-runner/
docker build -t selenium-side-runner .
cd -
```

### Start The Selenium Grid

Selenium Grid is started with the following command. Note that there are several images that will pull on the first run, but subsequent runs will be very fast.

```bash
docker compose -f docker-compose/selenium-v3-full-grid.yml up
```

Endpoint:

| Service          | Endpoint                      |
| :--------------- | :---------------------------- |
| Selenium Grid UI | http://localhost:4444/ui/#    |
| Jaeger           | http://localhost:16686/search |

### Start Selenium Grid Nodes

> :warning: This _may_ get resource intensive from this point forward. Close other applications as necessary when executing these tests.<br>
> :spiral_notepad: If _like_ execution profiles are desired, it is recommended that tests be run immediately after a localhost restart.<br>
> :bulb: The docker-compose files in this project use [service profiles](https://docs.docker.com/compose/how-tos/profiles/) for ease of maintenance and use.

Selenium Grid nodes can be launched in several configurations as needed. The following launches 3 nodes with a concurrency of 3 each.

```bash
docker compose -f ./docker-compose/selenium-grid-nodes-chrome.yml --profile run3 up
```

**Available Profiles**

- none: Defaults to 1 node.
- run1: 1 node.
- run3: 3 nodes.
- run5,run10,run15,run20: _n_ nodes.

To adjust the concurrency, see the `SE_NODE_MAX_SESSIONS=3` environment variable in [selenium-grid-nodes-chrome.yml](./docker-compose/selenium-grid-nodes-chrome.yml).

### Start The Test Site (Optional - 30s)

Start this test site to demo the included test-site [tests](./resources/tests/test-site/).

<details>
<summary>Build and run the Docker image</summary>

This will build the image and launch a daemonized container in the background, and finally return you to the base of this repository.

```bash
cd resources/test-site/
docker build -t test-site:latest .
docker run -d --rm --name test-site -v ./src:/app/src/ -p 8080:5173 test-site:latest
cd -
```

</details>

## Launch A Test Suite

With the Grid and Nodes up and running, and with a test target available (test site or otherwise), it's time to run a test suite.

Running a selenium-grid-nodes docker-compose will launch a series of nodes that connect to the Selenium Grid via the 'selenium-grid' Docker network. These nodes then execute the test suite for which they're configured. For example, this launches a single test execution against the test site.

```bash
docker compose -f ./docker-compose/selenium-side-runner--test-site.yml --profile test-site-x1 up
```

**Available Profiles**

- none: Runs 1 test.
- test-site-x1: Runs 1 tests.
- test-site-xn: Runs _n_ tests.
  - The 'xn' test dirs support the generation of fairly simple _load_ tests.
  - The .side file enabled by default in this repository is test_1000.side.
  - Don't worry, your computer can handle it, but it may take a few minutes.


## Creating New Test Suites

This is fairly easy.

1. Create a subdirectory under `tests/` with an appropriate name for the project.
1. Use the [Selenium IDE](https://chromewebstore.google.com/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd) to record a new test.
    - Note the availability of 'wait', 'if' and other command types that enable the tests to function well when run in CI/headless.
1. Copy one of the selenium-side-runner docker-compose files and adjust as necessary.
1. Run the test.

<details>

<summary>Recording a new test</summary>

Use the [Selenium IDE](https://chromewebstore.google.com/detail/selenium-ide/mooikfkahbdckldjjndioackbalphokd) Chrome Extension to record a test.

**Tips:**

- Enlarge the windows it opens.
- You can adjust the properties of each action (ie: window resize) by selecting it and editing the details.
- The right-click menu options are only available when the test IS NOT running.
- Use the "Wait for..." commands between steps to ensure that page are loaded and ready for interaction.
- Use the "Assert..." commands as needed.
- Get great at selectors
  - For non-trivial, non-unique elements, preference xpath selectors.
    - Use the xpath provided by the client you're testing rather than as detected by Selenium IDE.
      - Right click an element > Inspect :: Right click the code > Copy > Xpath.
      - Use the 'contains' argument for xpath. IE:
        - `xpath=[contains (text(), 'Cool Element')]`
        - `xpath=(//input[@value="I'm Feeling Lucky"][@type='submit'])`
    - Note: If an application wasn't developed with a strong selector posture, your tests will be brittle. Create issues/tickets for that project as needed.
- Note the parallel boolien in the .side config.

**References:**

- [Selenium IDE Commands](https://www.selenium.dev/selenium-ide/docs/en/api/commands)
- [Selenium IDE Arguments](https://www.selenium.dev/selenium-ide/docs/en/api/arguments)
- [Selenium Test Parallization](https://www.selenium.dev/selenium-ide/docs/en/introduction/command-line-runner#test-parallelization-in-a-suite)
- [W3: XPATH Syntax](https://www.w3schools.com/xml/xpath_syntax.asp)
- [XPATH in Selenium](https://www.browserstack.com/guide/xpath-in-selenium)
- [XPATH: Sibling/Preceding](https://www.roborabbit.com/blog/mastering-xpath-using-the-following-sibling-and-preceding-sibling-axes/)
- [XPATH: Axes](https://www.scientecheasy.com/2019/08/xpath-axes.html/)

</details>

### Creating _n_ tests

The x_n test dirs contain everything needed to BASH this out.

Required: `jq`,`sed`,`bash` (Update bash and coreutils if on a Mac -- no guarantees for Windows. Run in an Ubuntu VM?)

1. Copy one of the `x_n` dirs into your new project.
1. Delete any `*.side`, `*.disabled` files.
1. Adjust the test_body.template and test.template files as needed. The make_tests.sh script to combine and hydrates them. See the Main Operations of the script for more.

## Selenium Side Runner Options

Note that the image runs the following command and accepts _additional parameters_ via `command:` argument of docker-compose. An example of this can be found [here](./docker-compose/selenium-side-runner--test-site.yml). Here are the available args for selenium-side runner. Note that jest arguments can be passed in as well.

```bash
selenium-side-runner \
  --server http://$SE_HOST:4444/wd/hub \
  -c "goog:chromeOptions.args=[--headless,--nogpu] browserName=chrome" \
  --output-directory /root/out /sides/*.side \
  $@
```

<details>
<summary>selenium-side-runner help</summary>

```
Usage: selenium-side-runner [options] your-project-glob-here-*.side [variadic-project-globs-*.side]

Options:
  -V, --version                                   output the version number
  --base-url [url]                                Override the base URL that was set in the IDE
  -c, --capabilities [list]                       Webdriver capabilities
  -j, --jest-options [list]                       Options to configure Jest, wrap in extra quotes to allow shell to process (default: "\"\"")
  -s, --server [url]                              Webdriver remote server
  -r, --retries [number]                          Retry tests N times on failures, thin wrapper on jest.retryTimes (default: 0)
  -f, --filter [string]                           Run suites matching name, takes a regex without slashes, eg (^(hello|goodbye).*$)
  -w, --max-workers [number]                      Maximum amount of workers that will run your tests, defaults to number of cores
  -t, --timeout [number]                          The maximimum amount of time, in milliseconds, to spend attempting to locate an element. (default: 15000) (default: 15000)
  -T, --jest-timeout [number]                     The maximimum amount of time, in milliseconds, to wait for a test to finish. (default: 60000) (default: 60000)
  -x, --proxy-type [type]                         Type of proxy to use (one of: direct, manual, pac, socks, system)
  -y, --proxy-options [list]                      Proxy options to pass, for use with manual, pac and socks proxies
  -n, --config-file [filepath]                    Use specified YAML file for configuration. (default: .side.yml)
  -o, --output-directory [directory]              Write test results as json to file in specified directory. Name will be based on timestamp.
  -z, --screenshot-failure-directory [directory]  Write screenshots of failed tests to file in specified directory. Name will be based on test + timestamp.
  -f, --force                                     Forcibly run the project, regardless of project's version
  -d, --debug                                     Print debug logs
  -D, --debug-startup                             Print debug startup logs
  -X, --debug-connection-mode                     Debug driver connection mode
  -h, --help                                      display help for command
```

</details>
