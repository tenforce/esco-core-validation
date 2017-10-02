require_relative 'strings.rb'
helpers Helpers::Strings

###
# Helper module for creating triples
###

module Helpers
    module Triples
        ###
        # Runs one query
        #
        # create the query string and return it
        ###
        def build_results_query(query, application_graph, where_graph, rule_triples, data_type, time)
            insert_query = validation_result_prefix
            insert_query += "insert\n{\n"

            # putting the graph URI into the querystring
            insert_query += 'graph <' + application_graph + "> { \n "
            result_triples = result_triples_creator(rule_triples, data_type, time)

            insert_query += result_triples
            insert_query += "\n}}\nwhere{"
            insert_query += 'graph <' + where_graph + "> {\n"
            insert_query += query
            time_uuid = time.gsub(/\s/, '-').tr(':', '-')
            new_uuid = validation_result_uuid.gsub(/\btime\b/, time_uuid)
            new_uuid = new_uuid.gsub(/\brule\b/, rule_triples['ruleId'])
            new_uuid +="-language" if rule_triples['parameters'].include?('language')

            # we bind the result's uuid to the URI
            insert_query += " BIND (REPLACE(STR('" + new_uuid + "'), 'change_the_uuid', ?uuid) AS ?newuuid).\n" unless rule_triples['parameters'].include?('language')
            insert_query += " BIND (REPLACE(STR(REPLACE(STR('" + new_uuid + "'), 'language', ?language)), 'change_the_uuid', ?uuid) AS ?newuuid).\n" if rule_triples['parameters'].include?('language')
            insert_query += " BIND (URI(REPLACE(STR('" + validation_result + "'), 'change_the_uuid', ?newuuid)) AS ?newURI) }}"
            insert_query
        end

        def build_rule_query(application_graph, _where_graph, rule_triples)
            insert_query = validation_result_prefix
            insert_query += "insert data\n{\n"

            # putting the graph URI into the querystring
            insert_query += 'graph <' + application_graph + ">\n{"
            insert_query += rule_triples['rule_triples'].to_s
            insert_query += "\n}}"

            insert_query
        end

        ###
        # Create triples for rule
        #
        # example:
        # <http://mu.semte.ch/vocabularies/core/validationResultCollection/57cd7d7a9247d0021a000012>
        #                a mu:validationResultCollection ;
        #                mu:uuid '57cd7d7a9247d0021a000012';
        #                mu:timestamp '2016-08-25';
        #                mu:ruleId 'rule0' .
        ###
        def rule_triples_creator(rule_json, time, graph)
            rule = rule_json['rule']
            key = rule_json['key']
            parameters = rule['parameters']

            rule_uuid = generate_uuid
            rule_uri = '<' + validation_result_collection + rule_uuid + '>'

            # add type, uuid and timestamp, status
            rule_triples = rule_uri + " a mu:validationResultCollection ;\n"
            rule_triples += " mu:uuid '" + rule_uuid + "' ;\n"
            rule_triples += " mu:timestamp '" + time + "'^^xsd:dateTime ;\n"
            rule_triples += " mu:Graph '" + graph + "' ;\n" unless graph.nil?

            # end withadding a ruleId
            # and returning triples, uri and parameters
            rule_triples += " mu:ruleId '" + key + "' .\n\n"
            {
                'rule_triples' => rule_triples,
                'rule_uri' => rule_uri,
                'parameters' => parameters,
                'ruleId' => key
            }
        end

        ###
        # Create triples for results
        #
        # example:
        # <http://mu.semte.ch/vocabularies/core/validationResult/16120b46-533c-11e6-89a4-a439968efbe3>
        #                                                                                               a mu:validationResult ;
        #                                                                                               mu:uuid '16120b46-533c-11e6-89a4-a439968efbe3';
        #                                                                                               mu:language 'en' ;
        #                                                                                               mu:type 'concept' .
        #
        #
        # <http://mu.semte.ch/vocabularies/core/validationResultCollection/rule0-2016-08-25-10-41-23> mu:hasResult
        # <http://mu.semte.ch/vocabularies/core/validationResult/16120b46-533c-11e6-89a4-a439968efbe3> .
        ###
        def result_triples_creator(rule_triples, data_type, time)
            parameters = rule_triples['parameters']

            # start with type
            result_triples = "?newURI a mu:validationResult ;\n"
            result_triples += "mu:uuid ?newuuid;\n"
            result_triples += " mu:timestamp '" + time + "'^^xsd:dateTime ;\n"
            result_triples += " mu:ruleId '" + rule_triples['ruleId'] + "'  ;\n"

            # add each parameter
            parameters.each do |parameter|
                if parameter != 'type'
                    result_triples += 'mu:parameter' + parameter + ' ?' + parameter + " ;\n"
                end
            end

            # if there is a type
            # we add it as a uri
            if parameters.include?('type')
                result_triples = "BIND (URI(?type) AS ?typeuri) .\n" + result_triples
                result_triples += "mu:parametertype ?typeuri .\n"
            else
                # else we put data_type in there
                result_triples += "mu:parametertype '" + data_type + "' .\n"
            end

            # connect the Result to the Collection
            # and return the triples
            result_triples += rule_triples['rule_uri'] + " mu:hasResult ?newURI .\n"
            result_triples
        end
  end
end
