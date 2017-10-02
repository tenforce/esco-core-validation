# Validation service

This service runs validation queries to find invalid data in the database.

The service uses the [mu-semtech/mu-ruby-template:2.3.0-ruby2.3](https://github.com/mu-semtech/mu-ruby-template).

The responses are based on [JSON API](http://jsonapi.org).

This service offers the following API calls:

- fetch validation rules
- fetch the description of a validation rule
- run a validation rule's query (async)
- run selected or all queries (async)
- check for the status of the rules in the db
- check for the status of the temporary graph

It will also update the graph's metadata in the application database if another graph object has been provided and if all the queries are being run. It can validate any graphs, but the result triples will always be written in the application graph. By default it validates the application graph.

All the timestamps are in GMT!

## Configuration files

### types.json

Contains the prefixes for the types. These prefixes will be inserted into the query, if it appears in the types array.

#### Example type

```json
"concept" : "http://www.w3.org/2004/02/skos/core#Concept"
```

### rules.json

Contains all the rules with the following informations:

- id

  - Mandatory.
  - The id of the rule.
  - Has to be unique.

- name

  - Mandatory.
  - Short name of the rule.

- description

  - Mandatory.
  - Description what does this rule check.

- types

  - Mandatory.
  - It can be empty.
  - Types of the elements the rule checks for.
  - For using the types array the query has to contain `<change_the_type>`
  - If it is empty: The query has to return a type, otherwise the type attribute in the response will be empty.
  - If it is not empty: The query does not have to return a type, but it can. The service will create a different query for each type using the `<change_the_type>`

- show

  - Mandatory.
  - It can be empty.
  - If you want this rule to be visible in the front end, then add the name of your platform, e.g., "etms" to the show array.
  - In the front end addon, you have to define a platform name, and if that platform name is in this show array, then this rule will be visible in the client.

- parameters

  - Mandatory.
  - It has to contain at least the uuid.
  - To return a parameter, the name of the parameter has to appear in the parameters array otherwise it won't be included in the result triples.
  - If the types array is empty, then the query has to return type too.

- query

  - Mandatory.
  - The rule's SPARQL query containing only the part, that goes into the `where{}`.
  - The back end puts the `prefix mu: <http://mu.semte.ch/vocabularies/core/>` into the query automatically!
  - For using the types array the query has to contain `<change_the_type>`. Example: `?example a <change_the_type>`.
  - The back end puts the graph into the query automatically!

- template

  - Not mandatory
  - If the template exists, all parameters are mandatory.
  - If your query is too complex, but a part of it can be replaced by a value, you can use a template query.
  - `parameter`: You can have one parameter to be put in your original validation query. Must be the same as the 'return value' of your query.
  - `string`: You can set which strings should be swapped with the result of your query.
  - `query`: The select query of the template query.

#### Example rule

```json
"id": {
  "name": "Name of the rule.",
  "description": "Description of the rule.",
  "show":[
    "platform1"
  ],
  "types" : [
    "label"
  ],
  "parameters" :[
    "uuid",
    "label",
    "language"
  ],
  "query": "?label mu:uuid ?uuid ; a <change_the_type> . bind('changeLanguage' as ?language)",
  "template": {
      "string": "changeLanguage",
      "parameter": "template",
      "query": "select ?template where {<http://mu.semte.ch/application> <http://translation.escoportal.eu/supportedLanguage> ?template .}"
  }
}
```

## Fetch validation rules

### /validations

This GET call returns the rules.json file in JSON API format. The parameter `platforms` is mandatory. The backend will only return rules where the value of `platforms` is in the show array. Multiple platforms can be specified with commas. Example: `curl http://localhost:5000/validations?platforms=translation,etms`

### Example call with curl

`curl http://localhost:5000/validations?platforms=translation`

### Example reply

```json
{
    "data": [{
        "id": "multiple-prefterms",
        "type": "validation",
        "attributes": {
            "name": "Multiple prefterms",
            "description": "Every occupation should have only one preferred term in every language.",
            "show": ["translation"],
            "types": ["occupation"],
            "parameters": ["uuid", "preflabel", "language"],
            "query": "{SELECT ?concept ?uuid ?language ?preflabel COUNT(?prefterm) from <http://mu.semte.ch/application> where { ?concept a <change_the_type>. ?concept mu:uuid ?uuid. ?concept skosxl:prefLabel / skosxl:literalForm ?preflabel . FILTER(lang(?preflabel) = 'en') ?concept skosxl:prefLabel ?prefterm . ?prefterm skosxl:literalForm ?label. BIND(lang(?label) as ?language) FILTER(?language = 'changeLanguage') } GROUP BY ?concept ?language ?preflabel ?uuid HAVING(COUNT(?prefterm) > 1) }",
            "template": {
                "string": "changeLanguage",
                "parameter": "template",
                "query": "select ?template where {<http://mu.semte.ch/application> <http://translation.escoportal.eu/supportedLanguage> ?template .}"
            }
        }
    }]
}
```

## Fetch the description of a validation rule

### /:id/description

This GET call returns the rule's description, where the rule's id equals the :id parameter.

### Example call with curl #1

`curl http://localhost:5000/rule3/description`

### Example reply #1

```json
{
  "data": {
    "id": "rule3",
    "type": "description",
    "attributes": {
      "description": "If a preferred term is male, it must also be standard male."
    }
  }
}
```

### Example call with curl #2

When the id does not exists.

`curl http://localhost:5000/rule39/description`

### Example reply #2

It returns with an HTTP 404 Not Found error.

```json
{
  "errors": [
    {
      "title": "There is no validation rule with this ID."
    }
  ]
}
```

## Run a validation rule's query

### /:id/run

This POST call triggers the back end to run the rule's query, where the rule's id equals the :id. parameter.

It will create an insert{...} where{rule's query} SPARQL update query, and run it in the database. It triggers the query to start running async and it returns with an HTTP 202 Accepted with the timestamp and a status message as a meta.

The backend can run only one query at a time. Calling two run's with this endpoint won't work.

Because this is a POST call, we have to add `-X POST` to the curl call. Also, because we are not sending data to the back end during the call, we have to add `-H "Content-Length: 0"`.

### Example call with curl #1

`curl -v -X POST -H "Content-Length: 0" http://localhost:5000/rule3/run`

### Example reply #1

```
* Connected to localhost (127.0.0.1) port 5000 (#0)
> POST /rule3/run HTTP/1.1
> Host: localhost:5000
> User-Agent: curl/7.47.0
> Accept: */*
> Content-Length: 0
>
< HTTP/1.1 202 Accepted
< Content-Type: application/vnd.api+json
< Content-Length: 44
< X-Content-Type-Options: nosniff
< Server: WEBrick/1.3.1 (Ruby/2.3.1/2016-04-26)
< Date: Thu, 01 Sep 2016 14:09:25 GMT
< Connection: Keep-Alive
<
{ [44 bytes data]
100    44  100    44    0     0    137      0 --:--:-- --:--:-- --:--:--   137
* Connection #0 to host localhost left intact
```

```json
{
  "meta": {
    "status": "The call was accepted, the query started to run. Check back on /results for more details.",
    "attributes": {
      "timestamp": "2016-11-03 14:09:43"
    }
  }
}
```

### Example reply #2

```json
{
  "meta": {
    "status": "A query is already running, try again later."
  }
}
```

### Example reply #3

```
* Connected to localhost (127.0.0.1) port 5000 (#0)
> POST /rule39/run HTTP/1.1
> Host: localhost:5000
> User-Agent: curl/7.47.0
> Accept: */*
> Content-Length: 0
>
< HTTP/1.1 404 Not Found
< Content-Type: application/vnd.api+json
< Content-Length: 66
< X-Content-Type-Options: nosniff
< Server: WEBrick/1.3.1 (Ruby/2.3.1/2016-04-26)
< Date: Thu, 01 Sep 2016 14:28:44 GMT
< Connection: Keep-Alive
<
{ [66 bytes data]
100    66  100    66    0     0  11381      0 --:--:-- --:--:-- --:--:-- 13200
* Connection #0 to host localhost left intact
```

```json
{
  "errors": [
    {
      "title": "There is no validation rule with this ID."
    }
  ]
}
```

## Run selected or all validation rules

This POST call triggers the back end to run the selected/all queries. It will create an insert{...} where{rule's query} SPARQL update query for each rule, and run them in the database. It triggers the queries to start running async and it returns with an HTTP 202 Accepted with the timestamp and a status message as a meta.

Because this is a POST call, we have to add `-X POST` to the curl call. Also, because we are not sending data to the back end during the call, we have to add `-H "Content-Length: 0"`.

### /run

It runs all the queries that exist in the `rules.json`.

If a graph UUID is provided in the query string parameter "graph". It will run the validation on this graph and update the metadata at the end to mark the graph as valid or invalid.

### Example call with curl

`curl -X POST -H "Content-Length: 0" http://localhost:5000/run`

### Example on a specific graph

`curl -X POST -H "Content-Length: 0" http://localhost:5000/run?graph=cae85faa-93ce-49b5-ba3b-5ead9b7bbae9`

The metadata in the application graph (MU_APPLICATION_GRAPH) will be updated to reflect the graph validity.

### /run?keys=id1,id2

It runs selected queries. The selected queries' id has to be in the url after the `?keys=`, separated by commas, and no spaces are allowed.

### Example call with curl

`curl -X POST -H "Content-Length: 0" http://localhost:5000/run?keys=rule2,rule3`

### Example reply - same for both calls

```
* Connected to localhost (127.0.0.1) port 5000 (#0)
> POST /run HTTP/1.1
> Host: localhost:5000
> User-Agent: curl/7.47.0
> Accept: */*
> Content-Length: 0
>
  0     0    0     0    0     0      0      0 --:--:--  0:02:22 --:--:--     0< HTTP/1.1 202 Accepted
< Content-Type: application/vnd.api+json
< Content-Length: 44
< X-Content-Type-Options: nosniff
< Server: WEBrick/1.3.1 (Ruby/2.3.1/2016-04-26)
< Date: Thu, 01 Sep 2016 15:36:43 GMT
< Connection: Keep-Alive
<
{ [44 bytes data]
100    44    0    44    0     0      0      0 --:--:--  0:02:22 --:--:--    10
* Connection #0 to host localhost left intact
```

```json
{
  "meta": {
    "status": "The call was accepted, the query started to run. Check back on /results for more details.",
    "attributes": {
      "timestamp": "2016-11-03 14:09:43"
    }
  }
}
```

## Check the status of the rules in the db

This GET call will return a status message depending of the existence of the rule results in the db.

### /results?keys=id1,id2&date=2016-10-28&time=13:22:33

Asking for the status of selected rules.

- The selected queries' id has to be in the url after the `?keys=`, separated by commas, and no spaces are allowed.

  - If nothing is passed, it will look for all the queries -> if you started with the timestamp for one rule, it will always give 'still working' as a result, because the backend will think the rest is not finished yet.

- The timestamp has to be passed with the `&date=` and the `&time=` parameters.

  ### Example call with curl

`curl http://localhost:5000/results?keys=rule2,rule3&date=2016-10-28&time=13:22:33`

### Example reply - finished

```json
{
  "meta": {
    "status": "finished",
    "attributes": {
      "timestamp": "2016-11-03 14:09:43"
    }
  }
}
```

### Example reply - still working

```json
{
  "meta": {
    "status": "still working"
  }
}
```

### Example replies - no time

```json
{
  "errors": [
    {
      "title": "No timestamp was provided to the call."
    }
  ]
}
```

### Example replies - no date

```json
{
  "errors": [
    {
      "title": "No date was provided to the call."
    }
  ]
}
```

### /results?graph=graph_uuid

Returns the status of an esco temporary graph. Used after importing with the [import service](https://git.tenforce.com/esco/import-concepts) into a temporary graph and validating that temporary graph.

### Example call with curl

`curl "http://localhost:5000/results?graph=c06df04e-f41f-4172-acf6-699360bb71be"`

### Example reply

```json
{
  "meta": {
    "status": "http://data.europa.eu/esco/model#Validated"
  }
}
```

## How to run the validation-microservice

Use the following command from the validation-microservice folder. You have to add the port, the name of your database and the path to your code!

- Make sure to set a higher SPARQL timeout than 60 because these queries can be complex! You can use the mu-ruby-template `MU_SPARQL_TIMEOUT` environment variable for that.

- Make sure that you set the timeout and memory in your database higher then the default, for Virtuoso, you can do it in your virtuoso.ini file! To do that, you need to change the following attributes (I listed example numbers here):

  - NumberOfBuffers: 3400000
  - MaxDirtyBuffers: 6000
  - MaxQueryCostEstimationTime: 40000
  - MaxQueryExecutionTime: 6000

- Make sure to add a location to your config folder via the `CONFIG_DIR_VALIDATION` environment variable!

- If your database is running in another docker compose, you can use the `--network` to connect to it, example: `--network etmsplatform_default`

### Build

```
docker build -t validation-service:latest .
```

### Running development environment

```
docker run -it --rm -p 80:80 --name valid_service \
    -e MU_SPARQL_TIMEOUT=300 -e RACK_ENV=development \
    -v "$PWD"/example:/config \
    -v "$PWD":/app \
    --link name_of_your_database:database \
    validation-service
```

### Running production environment

```
docker run -p 80:80 --name valid_service \
    -e MU_SPARQL_TIMEOUT=300 \
    -v <PATH_TO_PRODUCTION_CONFIG>:/config \
    --link name_of_your_database:database \
    validation-service
```

# The old version

This is the updated version of the esco-validation-service. The previous (archived) version is [here](https://git.tenforce.com/esco/validation-service).
