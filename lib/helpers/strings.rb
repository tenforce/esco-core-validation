###
# Helper module for String constraints
###

module Helpers
    module Strings
        ###
        # variables for status messages / descriptions
        ###

        # invalid id
        def invalid_id_description
            'There is no validation rule with this ID.'
        end

        # multiple id
        def multiple_ids_provided
            'Multiple ids were provided to the call.'
        end
        # multiple id
        def no_id_provided
            'No id was provided to the call.'
        end

        # no timestamp
        def no_timestamp_provided
            'No timestamp was provided to the call.'
        end

        # multiple timestamp
        def multiple_timestamp_provided
            'Multiple timestamps were provided to the call.'
        end

        # no date
        def no_date_provided
            'No date was provided to the call.'
        end

        # accepted
        def accepted
            'The call was accepted, the query started to run. Check back on /results for more details.'
        end

        # accepted
        def already_running
            'A query is already running, try again later.'
        end

        # accepted
        def too_soon_to_run_again
            'The latest run was less than 30 minutes ago.'
        end

        ###
        # variables for JSON API types
        ###

        # variables for type
        def validation_type
            'validation'
        end

        # variable for type collection
        def validation_type_collection
            'validation-collection'
        end

        # variable for rules collection
        def rules_collection
            'rules-collection'
        end

        # variable for description
        def description_type
            'description'
        end

        # variable for timestamp
        def timestamp_type
            'timestamp'
        end

        ###
        # variables for triples
        ###

        # validation result URI
        def validation_result_uuid
            'validation-time-rule-change_the_uuid'
        end
        # validation result URI
        def validation_result
            'http://mu.semte.ch/vocabularies/core/validationResult/change_the_uuid'
        end

        # validation result URI_collection
        def validation_result_collection
            'http://mu.semte.ch/vocabularies/core/validationResultCollection/'
        end

        # validation result prefix
        def validation_result_prefix
            prefix = "prefix mu: <http://mu.semte.ch/vocabularies/core/>\n"
            prefix += "prefix mp: <http://sem.tenforce.com/vocabularies/mapping-platform/>\n"
            prefix += "prefix esco: <http://data.europa.eu/esco/model#>\n"
            prefix += "prefix escolabelrole: <http://data.europa.eu/esco/LabelRole#>\n"
            prefix += "prefix translation: <http://translation.escoportal.eu/>\n"
            prefix += "prefix translationvocab: <http://translation.escoportal.eu/vocab/>\n"
            prefix += "prefix skosxl: <http://www.w3.org/2008/05/skos-xl#>\n"
            prefix += "prefix etms: <http://sem.tenforce.com/vocabularies/etms/>\n"
            prefix += "prefix skos: <http://www.w3.org/2004/02/skos/core#>\n\n"

            prefix
        end

        ###
        # variables for metadata
        ###

        # invalid graph
        def invalid_graph_description
            'Can not find the graph'
        end
        # invalid graph
        def invalid_graph_status
            'Can not find status for this graph'
        end
    end
end
