# DRP PIP Conformance Test Suite

This document describes a system for testing the implementation of a Privacy Infrastructure Provider as specified in the [data rights protocol](https://github.com/consumer-reports-digital-lab/data-rights-protocol). 

## Introduction and Set Up

- This assumes a UNIX-like environment. Developed on linux, mostly assumed to be compatible with macOS and [WSL2](https://docs.microsoft.com/en-us/windows/wsl/about), I will work with folks to debug issues.
- This assumes you've cloned the [data-rights-protocol](https://github.com/consumer-reports-digital-lab/data-rights-protocol/) specification repository and ran `git submodule init` inside of it.
- This assumes you're working in a terminal which has been `cd cert`'d from inside of the specification git checkout.
- Follow the Introduction and Setup of the [Tools for the DRP Conformance Test Suite](conformance-tools.md) document and ensure you can enter a =poetry shell=.
- Open *three terminals*, make sure they're all inside of `poetry shell`.
  - inside the first run `swagger` to start the Swagger API viewer on http://localhost:8001/swagger .
  - inside the second run `statusserver` to start the testing Authorized Agent's Status Callback Server on http://localhost:8000
  - the third terminal will be used to submit the data rights requests embedded in this document.
- All of the shell script snippets included in this document can be copied in to a terminal, and any expected output is included below the commands, though rendering in GitHub or similar platforms may be confusing.

## Test Plans

This thing uses bash, curl, jq, and a bit of python to run conformance validations.

Remember to be in a =poetry shell=, remember to run =poetry install=

```
poetry install
poetry shell
```

These are variables you will want to change when you copy this in to the shell:

```
export DRP_TEST_CACHE=/tmp/drp-test/ #      (1)
export JWT_SECRET=my_jwts_are_secure #      (2)
export BUSINESS_DOMAIN=example.com   #      (3)
```

The test suite will store response data and other "interstitial" data in the location specified in 1, this should be Good Enough on POSIX systems. The secret in 2 is used to sign the JWTs when `genjwts` is invoked. 3 is used in the Data Rights Discovery Endpoint tests.

### Data Rights Discovery Endpoint

Validating behavior of [Section 2.01](https://github.com/consumer-reports-digital-lab/data-rights-protocol#201-get-well-knowndata-rightsjson-data-rights-discovery-endpoint) of spec.

[XXX] strike this? - For a general PIP API validation which is not fronting a "real" Covered Business these tests can probably be omitted. full flow versus "partial/point to point"

#### Covered Business's domain SHOULD have a `/.well-known/data-rights.json`

This `BUSINESS_DOMAIN` in 1 variable is used only in the Discovery Endpoint tests.

The intent of this test is to ensure that the PIPs which provide a `data-rights.json` well-known resource for their customers is providing one which exposes the URI.

```
$ curl -s $BUSINESS_DOMAIN/.well-known/data-rights.json \
     -o $DRP_TEST_CACHE/data-rights.json \
  || echo "NO GET: data-rights.json"
$ export DISCOVERY_FOUND=$(test -f $DRP_TEST_CACHE/data-rights.json)
$ export DISCOVERY_FILE=$DRP_TEST_CACHE/data-rights.json
```

#### Discovery Endpoint MUST Be Valid JSON

```
$ jq . $DISCOVERY_FILE
{
  "version": "0.4",
  "api_base": "https://example.com/data-rights",
  "actions": [
    "sale:opt-out",
    "sale:opt-in",
    "access",
    "deletion"
  ],
  "user_relationships": []
}
```

#### Discovery Endpoint MUST contain a version field

This Conformance Suite runs against version 0.4 of the protocol:

```
$ [[ "$(jq -r .version $DISCOVERY_FILE)" = "0.4" ]] \
  || echo "NO VERSION: 0.4"
```

#### Discovery Endpoint MUST provide an API base

```
$ [[ -n "$(jq -r .api_base $DISCOVERY_FILE)" ]] \
  || echo "NO API_BASE"
$ export API_BASE=$(jq -r .api_base $DISCOVERY_FILE)
```

#### Discovery Endpoint MUST provide a list of actions

```
$ [[ ! "$(jq ".actions|length" $DISCOVERY_FILE)" = "0" ]] \
  || echo "NO ACTIONS"
$ export ACTIONS=$(jq -r ".actions|@sh" $DISCOVERY_FILE | tr -d \')
$ echo $ACTIONS
```

#### Discovery endpoint MAY contain a `user_relationships` hint set

```
$ [[ ! "$(jq ".user_relationships|length" $DISCOVERY_FILE)" = "0" ]] \
  || echo "NO USER_RELATIONSHIPS"
```

### OIDC Flow Testing

*This is all entirely under-specified in the specification itself, and in the details of testing this. We will need to flesh this out later on.*

Most of the "is this valid OIDC?" will come through the [OpenID conformance suite](https://openid.net/certification/). What we need is a thing that can get a JWT signed by the Covered Business's `IDp`.

#### Discovery Endpoint references OIDC AS

... auto-discovery of the AS and query it for ID tokens

#### OIDC Flow generates a JWT

Doing this in the shell is probably infeasible... little python client with a chromium embedded in it to do the full OIDC flow?

it'll be needed for assembling a DRR for OIDC-supporting CBs...

### Data Rights Requests

#### Submitting Data Rights Requests using the [Tools for the DRP Conformance Test Suite](conformance-tools.md)

- Requests are generated with the `genreqs` tool and optionally with `genjwts` to modify the bundled JWT.
- Requests are submitted with the included `swagger` server available by running `swagger` inside your poetry shell.
- Each test case will include a command to generate the request, and optionally you'll be able to modify it or the JWT token generation to match your needs.

Most of the sections below consist of a **Recipe** and a table of **Behaviors** to test. Each behavior will be validated by running the recipe, performing a full Data Rights Request which is expected to end in a certain state.

Record results of the recipes in the tracking sheet

#### Test Cases

These commands generate Data Rights Requests suitable to be fed in to the swagger tool to run through the Test Matrix to validate API behaviors. The [test tools' documentation](conformance-tools.md) describe how these commands' invocations can be modified to change factors of the JWTs and Request objects to suit your needs.

- TC1: `reqs/donotsell.json` The PIP can accept a simple do not sell request
  [This](reqs/donotsell.json) is a simple CCPA Do Not Sell request with a dummy, "unverified" identity [token](jwts/simple.json). These types of requests are generally considered to have lower identity verification requirements [XXX].
    
        genjwts -t jwts/simple.json | genreqs -t reqs/donotsell.json 

- TC2: `jwts/verified.json` The PIP can accept "verified" credentials
  This test case validates that the PIP can accept a JWT token which has claims "marked" as verified. (See Appendix 1 for discussion)
    
        genjwts -t jwts/verified.json | genreqs -t reqs/donotsell.json

- TC3: `reqs/deletion.json` The PIP can accept deletion requests
  This will send a CCPA Deletion request with verified credentials attached.
  
        genjwts -t jwts/verified.json | genreqs -t reqs/deletion.json

- TC4: `reqs/access.json` broad access request without any specific scope

        genjwts -t jwts/verified.json | genreqs -t reqs/access.json

#### Testing Valid Request Flows

These requests should all complete in an affirmative end-state to validate the most basic behavior of the PIP.

##### Recipe

For each **Behavior** below:

- Generate the request from the referenced **Test Case**, and submit it in the Swagger tool.
  - Specified **Overrides** should be added as arguments to either of the `genjwts` or `genreqs` commands.
- Observe:
  - A 200 http status response
  - The response body is an [Exercise Status](https://github.com/consumer-reports-digital-lab/data-rights-protocol#303-schema-status-of-a-data-subject-exercise-request) in `open` status.
- record the request ID in to the tracking sheet
- Move the request from `open` to `in_progress` to `fulfilled`

##### Behaviors

| Behavior                                                        | Test Case | Overrides                       |
|-----------------------------------------------------------------|-----------|---------------------------------|
| The PIP can accept a simple do not sell request                 | TC1       | ❌                              |
| The PIP can accept a request with verified credentials          | TC2       | ❌                              |
| The PIP can accept a simple deletion request                    | TC3       | ❌                              |
| The PIP can accept a deletion request with verified credentials | TC3       | jwt: `-v email`                 |
| The PIP can accept a deletion request with verified credentials | TC3       | jwt: `-v phone_number -v email` |
| ...                                                             |           |                                 |

#### Agent Revocation Tests

(XXX: need to write these out still)

test cases:

- revoke immediately
- revoke in `need_user_verification` stage
- revoke while being processed `in_progress` by CB backend

#### Status Callback validation

(XXX: need to write these still)

#### Access Request

(XXX: need to write these still)

#### Tests for all Final States

(XXX: This is in progress)

##### Recipe

##### Behaviors

| Behavior                                                                 | Test Case   | Overrides        |
|--------------------------------------------------------------------------|-------------|------------------|
| Expect `claim_not_covered` for GDPR request for US phone number identity | TC3         | `-o regime=gdpr` |
| Expect `too_many_requests` after submitting repeated access requests     | TC4         |                  |
| Valid-but-garbage token should end in `no_match`                         | TC1 TC3 TC4 |                  |
| ...                                                                      |             |                  |


#### Need User Verification testing

ughghghghgh

This will use a web browser, i guess...? This is where designing these test cases is going to suck the most.

The redirect URL is another thing for the little Heroku app? it's a "nice to have", mostly, though.

- Load `user_verification_url` in browser with some URL parameters attached
  - `request_id` associated with the test case
  - `identity` param w/ the JWT associated with the test case
  - `redirect_to` must be set to "something", not sure what..

# Appendices

## Appendix 1: But what is "verified" what is meant by "marked"?

The claims in the identity tokens are basically based on [schema.org/Person](https://schema.org/Person) attributes, but specified in **OIDC Core 1.0**, [Section 5.1](https://openid.net/specs/openid-connect-core-1_0.html#rfc.section.5.1) (Standard Claims). Consider `phone_number` and `phone_number_verified`:

> True if the End-User's phone number has been verified; otherwise false. When this Claim Value is true, this means that the OP took affirmative steps to ensure that this phone number was controlled by the End-User at the time the verification was performed. The means by which a phone number is verified is context-specific, and dependent upon the trust framework or contractual agreements within which the parties are operating. When true, the phone<sub>number</sub> Claim MUST be in E.164 format and any extensions MUST be represented in RFC 3966 format.

And thus spoke, the question is our "what is our trust framework or contractual agreements?". This is work for the [governance documentation](../governance.md) to cover.
