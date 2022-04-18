# Tools for the DRP Conformance Test Suite

## Introduction and Setup

These are simple utilities and test fixtures used to drive the [[id:20211116T134053.585822][DRP Conformance Test Suite]].

They're all as simple as can be and written against Python 3.9. Please use a modern Python, the tools here make heavy use of modern Python features like type hinting to provide somewhat "magical" serialization and deserialization of Data Rights Requests.

I recommend installing Python 3.9 in accordance with your operating system's best principles[^1], and then install [Poetry](https://python-poetry.org/docs/) following that documentation. Once you have poetry installed (you should be able to run `poetry about` to report that the installation looks right), you can set up and enter a virtual environment with the test suite's dependencies by running:

```
poetry install
poetry shell
```

You will also need to install [JQ](https://stedolan.github.io/jq/) and [curl](https://curl.se/). The authors recommend you get these from Homebrew or a similar package manager.

### Some Alternatives

#### Nix Dev Shell

The developer of this suite uses a specialized Linux distribution called NixOS. Folks who use it or the [Nix Packaging Manager](https://nixos.org/) it's built on can use the `shell.nix` provided to create a hermetic environment for the toolkit which can be instantiated via [Nix Shell](https://nixos.wiki/wiki/Development_environment_with_nix-shell) command `nix-shell`.

## `genjwts`: JWT Generation script

[tools/genjwts.py](src/datarightsprotocol/tools/genjwts.py) is a script to generate JWTs signed by a bundled certificate as if it came from a test Authorized Agent.

This will only generate them but not decode or verify existing JWTs. Use [[https://jwt.io][the JWT Debugger]] instead.

```
$ genjwts --help
Usage: genjwts [OPTIONS]

  Small utility function to generate an IdentityPayload and serialize it.

Options:
  -s, --secret TEXT    JWT HS256 signing key
  -t, --template TEXT  JWT template to populate
  -o, --override TEXT  specify overrides to the JWT template in the form of
                       'claim=val'. can be specified repeatedly.
  -v, --verify TEXT    specify claims to mark as 'verified'.
  --help               Show this message and exit.
```

inside of [./jwts](jwts/) we'll find some JSON templates which can be used with this tool:

```
$ genjwts -t jwts/simple.json
Constructing claim.
Overriding template: []
Verifying claims: ()

Your JWT has arrived.
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0._CbiyDqnorHtPwl-Z81y9m6f3tuhKDzFXSVu2qoJK14
```

All "debug" messages are sent to `STDERR` so you can safely use this in a shell pipeline or get only the JWT output to your terminal like:

```
$ genjwts -t jwts/simple.json 2>/dev/null
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0._CbiyDqnorHtPwl-Z81y9m6f3tuhKDzFXSVu2qoJK14
```

claims can be overridden by passing any `--override` options:

```
$ genjwts -t jwts/simple.json -o name="ryan rix" -o email="drp@rix.si" 
Constructing claim.
Overriding template: [['name', 'ryan rix'], ['email', 'drp@rix.si']]
Verifying claims: ()

Your JWT has arrived.
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoicnlhbiByaXgiLCJwb3dlcl9vZl9hdHRvcm5leSI6bnVsbCwiZW1haWwiOiJkcnBAcml4LnNpIiwicGhvbmVfbnVtYmVyIjoiMSA2MDIgNTU1IDEyMTIifQ.Sh9iZhDBc-9SyoDRBv7cZvuzlhtsrVE9OGcHVRoI4TI
``` 

claims can be marked as verified by passing any number of =--verify= options:

```
$ genjwts -t jwts/simple.json -v email
Constructing claim.
Overriding template: []
Verifying claims: ('email',)

eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsX3ZlcmlmaWVkIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0.RtaiT4cU83F4CDEU9WvgjWBxBTy9rzdy6Gh0c_q6WXw
```

### What About the Secrets?

This thing basically only supports =HS256= signature-only JWTs in its current implementation, and loads the secret from an environment variable =JWT_SECRET=. So:

```
$ export JWT_SECRET=''; echo secret is $JWT_SECRET # default embedded in the code!
secret is
$ genjwts -t jwts/simple.json 2>/dev/null
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0._CbiyDqnorHtPwl-Z81y9m6f3tuhKDzFXSVu2qoJK14
$ export JWT_SECRET='thisisdifferent!'; echo secret is $JWT_SECRET
secret is thisisdifferent!
$ genjwts -t jwts/simple.json 2>/dev/null
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0.xf9KcMqiUE1x_JramIup5SVtAwWHcu_2EPTiSTT-ByA
```

It will need to be extended to support referring to an x509 certificate or multiple to support testing JWT encryption, and the x509 signatures which are required to enclose the trust network of a DRP implementers' network.

## `genreqs`: Rights Request Generation Script

[tools/genreqs.py](src/datarightsprotocol/tools/genreqs.py) composes with the JWT generation script to create entire Data Rights Requests. Like the JWT generation script, the `stderr` output can be stuffed in to `/dev/null` for cleaner output.

```
$ genreqs --help
Usage: genreqs [OPTIONS]

  Small utility function to generate a DataRightsRequest and serialize it.

Options:
  -t, --template FILENAME  DRR template to populate.
  -j, --jwt FILENAME       Generate a JWT using the specified template,
                           otherwise read a serialized JWT from stdin (&
                           probably out of genjwts.py)
  -o, --override TEXT      Specify overrides to DRR values. Values specified
                           as a list will be overwritten on first override,
                           then appended to after, if that makes sense.
  --help                   Show this message and exit.
```

In [./reqs](./reqs) we'll find some files containing JSON templates for the base Data Rights Requests.

In its default invocation, it will attempt to read a JWT from `stdin`. You can also pass a `--jwt` argument to specify a default JSON template with the default `genjwts` invocation.

```
$ genreqs -t reqs/donotsell.json -j jwts/simple.json 2>/dev/null
{"meta": {"version": "0.4"}, "relationships": [], "regime": "ccpa", "exercise": ["sale:opt-out"], "identity": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0._CbiyDqnorHtPwl-Z81y9m6f3tuhKDzFXSVu2qoJK14"}
```

To create customized JWTs, use the `stdin` invocation (note that each command in the pipelines needs its `stderr` stuffed!):

```
$ genjwts -v email 2>/dev/null | genreqs -t reqs/donotsell.json 2>/dev/null
{
  "meta": {
    "version": "0.4"
  },
  "relationships": [],
  "regime": "ccpa",
  "exercise": [
    "sale:opt-out"
  ],
  "identity": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsX3ZlcmlmaWVkIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0.RtaiT4cU83F4CDEU9WvgjWBxBTy9rzdy6Gh0c_q6WXw\n"
}
```

Overrides can be set in the `genreqs` script:

```
$ genreqs -j jwts/simple.json -t reqs/donotsell.json -o regime=voluntary 2>/dev/null
{"meta": {"version": "0.4"}, "relationships": [], "regime": ["voluntary"], "exercise": ["sale:opt-out"], "identity": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJwaXAtdGVzdC1zdWl0ZSIsImF1ZCI6InRoZS1waXAiLCJzdWIiOiJ0aGUtY29uc3VtZXIiLCJuYW1lIjoidGhlLWNvbnN1bWVyIiwicG93ZXJfb2ZfYXR0b3JuZXkiOm51bGwsImVtYWlsIjoidGVzdGNvbnN1bWVyQGNvbnN1bWVyLm9yZyIsInBob25lX251bWJlciI6IjEgNjAyIDU1NSAxMjEyIn0._CbiyDqnorHtPwl-Z81y9m6f3tuhKDzFXSVu2qoJK14"}
```

## `openapi.yaml` and a [Swagger](https://swagger.io) server to submit to the PIP

the [OpenAPI](https://www.openapis.org/) specification is a machine-readable description schema for describing APIs on the web. We'll be using this with a tool called [Swagger](https://swagger.io/) which provides an web app that can submit requests to APIs based on that =openapi= spec. This combination will allow for the "DRP certifier" to submit DRRs copied out of static JSON files or construct their own with DRRs generated by the above tooling.

[openapi.yaml](../openapi.yaml) provides a PIP-interface YAML specification. It can be used to submit DRP requests to a PIP instance and is foundational for the tests in the DRP PIP [conformance tests](./pip-conformance-test.md).

*Be sure to edit `openapi.yaml`'s servers list to add the API instance you are testing*

After running `poetry shell`, the command `swagger` will start this HTTP server.

```
$ swagger --help
Usage: swagger [OPTIONS]

  start the DRP swagger tool.

Options:
  -h, --host TEXT     the host IP to listen on, defaults to all IPs/interfaces
  -p, --port INTEGER  port to listen on
  --help              Show this message and exit.
```

changing the `DRP_OPENAPI` environment variable to point to another `openapi.yaml` or `swagger.json` file is the only other useful configuration element.[^2]

Running `swagger` will print the URL it is visible on in the terminal output, but by default it is [here on port 8001](http://0.0.0.0:8001/swagger).

## `statusserver` Status Callback Server

Recall that the DRP specification defines a "[`status_callback`](https://github.com/rrix/data-rights-protocol/blob/main/data-rights-protocol.md#204-post-status_callback-data-rights-status-callback-endpoint)" which is to be implemented by the *Authorized Agent* so that the *Privacy Infrastructure Provider or Covered Business* can push status changes to the AA rather than force the AA to poll a server every hour or day.

To test this flow, though, we need a server which has two endpoints:

- an HTTP POST receiver which can be set as the callback server in the `/exercise` request, it does nothing but log the Data Rights Status to a local database with a 2-3 day retention policy applied to the data.
- `GET /status?request_id=FOO` which can be queried by the certifier to list all of the state transitions recorded for the given request ID.

In [status_server.py](src/datarightsprotocol/tools/status_server.py) there is a dead-simple FastAPI server in less than 100 lines of Python which will behave as a status callback server and persist DRP status updates to disk.

[nb: i know i should provide better/stronger guidance here, this will "boil up" to a setup doc at the top of this with a full set of recommendations perhaps getting it running in a Docker container which can be hosted or run locally ...]

Invoke it from the DRP git checkout: `uvicorn status_server:app` and browse to http://localhost:8000 .

Now, somehow, this needs to be hosted on the World Wide Web so that your PIP implementation can contact it. [ngrok](https://ngrok.com/) and [cloudflared tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup) are the best recommendations the author has for this at the moment, both offer free accounts, but you may consider hosting this somewhere.

# Footnotes

[^1]: I will note that the author has not verified that this works on macOS or Windows. There is an assumption within this document and the Test Suite that you will have access to a POSIX-style shell. I have no idea how `poetry shell` works in cmd.exe or powershell, I would highly recommend setting up a WSL2 system. My apologies.

[^2]: Unfortunately it's not so simple to add a command line flag because of how the FastAPI uvicorn app is instantiated, we don't have access to the `click` command line flags..
