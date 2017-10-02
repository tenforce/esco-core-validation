require_relative 'jsonapi.rb'
helpers Helpers::Jsonapi
require_relative 'strings.rb'
helpers Helpers::Strings
require_relative 'triples.rb'
helpers Helpers::Triples

###
# Helper module for running the queries
# requires the Jsonapi module
# requires the Strings module
# requires the Triples module
###

module Helpers
    module Query
        ###
        # Run the queries
        # if the queries' key is in the keys array
        ###
        def run_queries_by_keys(keys, application_graph, where_graph, config, time, graph_uuid = nil)
            config_rules = config.get_rules
            config_types = config.get_types

            # get the current time
            # parse it to YYYY-mm-dd HH:MM:SS^^xsd:dateTime

            # do the same for each key
            keys.each do |key|
                # if there is a key for that rule then continue
                # otherwise go to the next key
                #
                # skip, if the rule already exists in the db
                # with today's date
                next unless config_rules.key?(key)
                rule = config_rules.fetch(key)
                rule_json = {
                    'rule' => rule,
                    'key' => key
                }

                # create and pass the rule triples
                # then run the query
                graph = nil
                graph = where_graph if where_graph != application_graph

                rule_triples = rule_triples_creator(rule_json, time, graph_uuid)
                if rule['template'].nil?
                    run_multiple_queries(rule, application_graph, where_graph, config_types, rule_triples, time)
                else
                    run_query_with_template(rule, application_graph, where_graph, config_types, rule_triples, time)
                end
                insert_query_rule = build_rule_query(application_graph, where_graph, rule_triples)
                update(insert_query_rule)
            end
        end

        ###
        # Run query with template
        #
        # if there is a template query, run it
        # then map the results
        # and swap the template string with the results of the templates
        # and run the new query (with types and stuffs)
        ###

        private

        def run_query_with_template(rule, application_graph, where_graph, config_types, rule_triples, time)
            query_string = rule['query']
            template_parameter = rule['template']['parameter'].to_s

            # run the template query
            query(rule['template']['query']).map do |row|
                # swap the template string with the query result
                rule['query'] = query_string.gsub(rule['template']['string'], row[template_parameter].to_s)
                run_multiple_queries(rule, application_graph, where_graph, config_types, rule_triples, time)
            end
        end
        ###
        # Runs multiple queries
        #
        # if there are types specified, it will iterate over the types
        # and create a new query string for each type
        # otherwise it will just run the given query
        ###

        private

        def run_multiple_queries(rule, application_graph, where_graph, config_types, rule_triples, time)
            query_string = rule['query']
            query_types = rule['types']

            # just run the query if no type was specified
            if query_types.empty?
                run_one_query(query_string, application_graph, where_graph, rule_triples, '', time)
            else
                # otherwise / if types were specified
                # create a query for each type and run it
                query_types.each do |type|
                    # if that type exists in the types.json
                    # then continue
                    # otherwise go to the next type
                    next unless config_types.key?(type)
                    change_type = config_types.fetch(type)

                    # put the type uri into the query
                    # run the query
                    new_query_string = query_string
                                       .gsub(/\bchange_the_type\b/, change_type)
                                       .gsub(/\bapplication_graph\b/, application_graph)
                    run_one_query(new_query_string, application_graph, where_graph, rule_triples, type, time)
                end
            end
        end

        ###
        # Runs one query
        #
        # first we create and run the insert{..}where{..} query
        # this selects all results, creates the result triples and inserts them into the database
        # then we create and run the rule triples insert data{...}
        # with a status that says it is finished
        # the rule triples will be only inserted if all the result triples are already inserted
        ###

        private

        def run_one_query(query_string, application_graph, where_graph, rule_triples, type, time)
            insert_query = build_results_query(query_string, application_graph, where_graph, rule_triples, type, time)
            update(insert_query)
        end

        ###
        # Checks if the rule was already run today or not
        #
        # checks for exsistence of the rule triples for today
        # those triples only get inserted, when the result triples got inserted
        # returns a boolean
        ###

        private

        def check_rule_existence_in_db(_rulekey, application_graph, time)
            query_string = "prefix mu: <http://mu.semte.ch/vocabularies/core/>\n"
            query_string += "ask\n"
            query_string += 'from <' + application_graph + ">\n"
            query_string += "where{\n"
            query_string += "?s a mu:validationResultCollection;\n"
            query_string += "mu:timestamp '" + time + "'^^xsd:dateTime ;\n"
            query_string += "mu:ruleId '" + _rulekey + "'.}"

            query(query_string)
        end
    end
end
