# DRP Certification Test Suite and implementation tools

This repository contains the test suite and a number of simple automation tools which drive the test suite.

The test plan itself is still in a pretty rough shape, I've been focused on building up the scaffolding and designing the tools so that we don't drown in JSON files and now all that's left is those JSON files and the test suite itself. I'm planning to start delivering that part this week in this repository.

Find:

- [Conformance Test Suite tools guide](conformance-tools.md) collects the "readme"s for the various little utilities which are used to support that doc. Start here to learn how to set up your environment for operating the PIP and AA test suites.
- (draft) [PIP Conformance Test Suite Doc](pip-conformance-test.md) is used to guide the certification suite for PIPs 
- (draft) [AA Conformance Test Suite Doc](aa-conformance-test.md) is used to similarly guide the certification suite for AAs
- [src/datarightsprotocol/models](src/datarightsprotocol/models/) contains a handful of Python 3 Pydantic modules which can be used to serialize and de-serialize DRP objects
- [jwts directory](jwts/) contains example identity tokens
- [reqs directory](reqs/) contains example Data Rights Requests
