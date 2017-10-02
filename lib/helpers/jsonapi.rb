###
# Helper module for creating JSON API answers
###

module Helpers
    module Jsonapi
        ###
        # Creates a json from the submitted parameters
        #
        # format: JSON API
        #
        # always have id and type
        # if not empty include 'attributes'
        # if not empty include 'relationships'
        # if not empty include 'included'
        ###
        def create_response_json(_id, _type, _attributes = {}, _relationships = {}, _included = [])
            data = {}
            data['id'] = _id
            data['type'] = _type
            data['attributes'] = _attributes unless _attributes.empty?
            unless _relationships.empty?
                data['relationships'] = {}
                data['relationships']['data'] = _relationships
            end
            result = {}
            result['data'] = data
            result['included'] = _included unless _included.empty?
            result.to_json
        end

        ###
        # Creates a hash from the submitted parameters
        #
        # format: JSON API
        #
        # always have id and type
        # if not empty include 'attributes'
        # if not empty include 'relationships'
        # if not empty include 'included'
        ###
        def create_data_hash(_id, _type, _attributes = {}, _relationships = {})
            result = {}
            result['id'] = _id
            result['type'] = _type
            result['attributes'] = _attributes unless _attributes.empty?
            unless _relationships.empty?
                data['relationships'] = {}
                data['relationships']['data'] = _relationships
            end
            result
        end

        ###
        # Creates a hash for each relationship
        #
        # format: JSON API
        ###
        def create_relation_hash(_id, _type)
            result = {}
            result['id'] = _id
            result['type'] = _type
            result
        end

        ###
        # Creates a hash for each relationship
        #
        # format: JSON API
        ###
        def create_timestamp_hash(_id, _type, _attributes = {})
            result = {}
            result['id'] = _id
            result['type'] = _type
            result['attributes'] = _attributes
            result.to_json
        end

        ###
        # Creates a meta json and return status
        # return timestamp too if it exists
        #
        # format: JSON API
        ###
        def create_meta_json(status, _attributes = '')
            meta = {}
            meta['status'] = status
            meta['attributes'] = _attributes unless _attributes.empty?
            result = {}
            result['meta'] = meta
            result.to_json
        end
  end
end
