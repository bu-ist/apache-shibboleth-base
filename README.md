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

