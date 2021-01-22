# shib-sp-test
Simple Shibboleth SP test

## How to build a set of key and certificates

./keygen.sh -o directory -h hostname -y years

I would use something like 10 years for the years.

## Automatic testing

The test subdirectory will generate an internal environment for testing.  This will start with simple
unit testing like the WebRouter component but should eventually do fully internal testing (look at 
Unicon's repos for an example).

The auto-shib-sp-test.yml docker-compose file will automatically build the test environment and run the tests.
A non-zero response code from the sut container indicates that the test failed.  You can run the tests 
manually by doing:

```
docker-compose -f auto-shib-sp-test.yml up 
```


## Shibboleth SP configuration

In order to be able to use Shibboleth for authentication, we need two components:

1. Shibboleth SP needs to be configured with some unique private key and entityID
(same for all applications in the same landscape, in general case).

1. Shibboleth IdP needs to be provided with the metadata file of the SP,
its entityID and also be configured to release all required attributes.

To configure Shibboleth SP, one needs:

- Pick some arbitrary entityID (we chose
`https://phpbin-apps-nonprod.bu.edu/shibboleth-sp` and `https://phpbin-apps-prod.bu.edu/shibboleth-sp`)

- Use `./keygen.sh -o secrets ...` to generate the private/public keypair (<https://github.com/bu-ist/apache-shib-sp>).

- Rename files in the `secrets` directory to `SHIB_SP_CERT` and `SHIB_SP_KEY`

- Add `sp_sp` variable to the `docker-compose.yml` and run `docker-compose up --build --force-recreate`

- Download the metadata file from <http://localhost:8000/Shibboleth.sso/Metadata>

- [Follow instructions](#shibboleth-secrets) to upload this keypair to the secrets bucket.

To configure Shibboleth IdP, submit a ticket with Server Administrators.
The ticket should include the following:

- The entityID of your choice

- Technical contact: `antonk`, `bfenster`

- Mention that you need all standard attributes to be released plus
`buPrincipalNameID` (required for Web Accounts integration)

- Ask to double check that the `skipEndpointValidationWhenSigned` option is
set to `true` in `relying-party.xml` for this SP. This is default at the time
of writing this but there were discussions regarding making it non-default.

- Attach the metadata file

See this ticket for example: INC12816603.
