require_relative 'strings.rb'
helpers Helpers::Strings

module Helpers
    module Metadata

        def find_graph(graph, uuid)
            data_set = query(<<-QUERY)
                PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
                PREFIX esco: <http://data.europa.eu/esco/model#>

                SELECT ?graph
                FROM <#{graph}>
                WHERE
                {
                  ?x mu:uuid "#{uuid}" ;
                  a esco:Graph ;
                  esco:graph ?graph .
                }
                QUERY
            if data_set.length == 0
                nil
            else
                data_set.first["graph"].to_s
            end
        end

        def update_metadata(graph, uuid, timestamp)
            update(<<-QUERY)
                PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
                PREFIX esco: <http://data.europa.eu/esco/model#>

                WITH <#{graph}>
                DELETE
                {
                  ?x esco:status ?previous .
                }
                INSERT
                {
                  ?x esco:status ?status .
                }
                WHERE
                {
                  ?x a esco:Graph ;
                  mu:uuid "#{uuid}" .
                  OPTIONAL { ?x esco:status ?previous } .

                  BIND(EXISTS {
                    ?y a mu:validationResultCollection ;
                    mu:timestamp "#{timestamp}"^^xsd:dateTime ;
                    mu:hasResult ?z ;
                    mu:Graph "#{uuid}".
                  } AS ?resultsFound) .

                  BIND(IF(?resultsFound, esco:Invalid, esco:Validated) AS ?status) .

                }
                QUERY
        end

        def setUnderValidation(graph, uuid)
            update(<<-QUERY)
                PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
                PREFIX esco: <http://data.europa.eu/esco/model#>

                WITH <#{graph}>
                DELETE
                {
                  ?x esco:status ?previous .
                }
                INSERT
                {
                  ?x esco:status esco:underValidation .
                }
                WHERE
                {
                  ?x a esco:Graph ;
                  mu:uuid "#{uuid}" .
                  OPTIONAL { ?x esco:status ?previous } .

                }
                QUERY
        end

        def getGraphStatus(graph, uuid)
            data_set = query(<<-QUERY)
                PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
                PREFIX esco: <http://data.europa.eu/esco/model#>

                SELECT ?status
                FROM <#{graph}>
                WHERE
                {
                  ?x mu:uuid "#{uuid}" ;
                  a esco:Graph ;
                  esco:graph ?graph ;
                  esco:status ?status.
                }
                QUERY
            if data_set.length == 0
                nil
            else
                data_set.first["status"].to_s
            end
        end

    end
end
