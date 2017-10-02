require 'net/http'
require 'json'
# require 'pry'# for breakpoints

require_relative 'lib/file_handler.rb'
require_relative 'lib/time_handler.rb'

require_relative 'lib/helpers/query.rb'
require_relative 'lib/helpers/metadata.rb'
require_relative 'lib/helpers/jsonapi.rb'
require_relative 'lib/helpers/strings.rb'
helpers Helpers::Query
helpers Helpers::Metadata
helpers Helpers::Jsonapi
helpers Helpers::Strings

###
# requires the Query modules
# requires the Jsonapi modules
# requires the Strings modules
# requires the Metadata modules
###

# variable to handle reading from the config file
config = FileHandler.new
config_dir_location = ENV['CONFIG_DIR_VALIDATION'] || "/config"
config.set_dir(config_dir_location)

config_times = TimeHandler.new(config.get_rules)
error_message = nil
read_timeout = 600

###############
#### Calls ####
###############

###
# Returns all rules from the rules config file
###
get '/' do
    content_type 'application/vnd.api+json'

    rules = config.get_rules
    included_array = []
    relationships = []
    platforms = []
    platforms = params[:platforms].split(',') if params[:platforms]


    # creating a relationship for the rule
    # adding it to the relationship array
    # because a rule is related to the rules-collection
    #
    # insert the graph URI into the query
    # and replace the old query string with the new query string
    # create a json from each rule and put it into the included array
    rules.each do |attribute_key, attribute_value|
        # check if the platforms parameter is in the show array
        # if so, we will return that rule
        unless (platforms & attribute_value['show']).empty?
          relationship = create_relation_hash(attribute_key, validation_type)
          relationships.push(relationship)

          # put the graph into the query
          graph_text = 'from <' + settings.graph.to_s + ">\nwhere"
          attribute_value['query'] = attribute_value['query'].gsub(/\b(?i)(where)\b/, graph_text)
          included_array.push(create_data_hash(attribute_key, validation_type, attribute_value))
        end
    end
    results = {}
    results['data'] = included_array
    results.to_json
end

###
# If a rule exists with this ID
# returns the description
###
get '/:id/description' do
    content_type 'application/vnd.api+json'
    rules = config.get_rules
    key = params[:id]

    # check if there is a rule with this id
    # if so, return the description
    if rules.key?(key)
        attributes = {}
        attributes['description'] = rules.fetch(key)['description']
        return create_response_json(key, description_type, attributes)
    else
        error(invalid_id_description, status = 404)
    end
end

###
# If a rule exists with this ID runs its query
# returns a status json if the query executed
###
post '/:id/run' do
    content_type 'application/vnd.api+json'

    if config_times.is_something_running
        status 200
        return create_meta_json(already_running)
    end

    error_message = nil
    config_rules = config.get_rules
    config_types = config.get_types
    key = params[:id]

    # check if there is a rule with this id
    # if so, run the queries
    # and return the timestamp
    if config_rules.key?(key)
        # setting the timezone always to GMT
        timestamp = Time.now.getlocal("+00:00").strftime('%F %T')
        # run_again = config_times.can_run_again(key, timestamp)
        keys = [key]

        # unless (run_again == true) || (run_again == 0)
        #     attributes = {
        #         'latest_run' => config_times.get_latest(key),
        #         'run_again' => run_again
        #     }
        #     status 200
        #     return create_meta_json(too_soon_to_run_again, attributes)
        # end

        Thread.new do
          begin
              config_times.set_running(key, true)
              run_queries_by_keys(keys, settings.graph.to_s, settings.graph.to_s, config, timestamp.to_s)
              config_times.set_running(key, false)
              # config_times.set_latest(key, timestamp)
          rescue Exception => e
              config_times.set_running(key, false)
              error_message = e.message
              log.error e.message
          end
        end
        attributes = {
            'timestamp' => timestamp
        }
        status 202
        create_meta_json(accepted, attributes)
    else
        error(invalid_id_description, status = 404)
    end
end

###
# Run all validations
# if there are keys passed, run only those validations
# returns a status json if the query executed
###
post '/run' do
    content_type 'application/vnd.api+json'
    error_message = nil

    # if there is a `keys` parameter
    # split up by ,
    # else or if the keys paramter was empty
    # get the keys from the rules config
    keys = []
    keys = params[:keys].split(',') if params[:keys]
    all_keys = keys.empty?
    keys = config.get_rules.keys if all_keys

    # setting the timezone always to GMT
    timestamp = Time.now.getlocal("+00:00").strftime('%F %T').to_s

    graph_uuid = params[:graph]
    graph_to_validate = if graph_uuid.nil?
                            settings.graph.to_s
                        else
                            find_graph(settings.graph.to_s, graph_uuid)
                        end

    if graph_to_validate.nil?

        error(invalid_graph_description, status = 404)

    else
        Thread.new do
            begin
                if !graph_uuid.nil? && all_keys
                    setUnderValidation(settings.graph.to_s, graph_uuid)
                end

                run_queries_by_keys(keys, settings.graph.to_s, graph_to_validate, config, timestamp, graph_uuid)

                # keys.each do |key|
                #   config_times.set_latest(key, timestamp)
                # end

                if !graph_uuid.nil? && all_keys
                    update_metadata(settings.graph.to_s, graph_uuid, timestamp)
                end

            rescue Exception => e
                error_message = e.message
                log.error e.message
            end
        end

        status 202
        create_meta_json(accepted, timestamp)
    end
end

###
# Check for rule status in db
# if there are keys passed, run only those validations
# if a graph_uuid was passed, return the graph's status
# returns a status json if the query executed
###
get '/results' do
    content_type 'application/vnd.api+json'
    error(error_message, status = 500) unless error_message.nil?

    # we get the temporary graph uuid
    # if the graph_uuid is not nil
    # we return the status
    # if the status is nil, then it is an invalid graph
    graph_uuid = params[:graph]
    unless graph_uuid.nil?
        status = getGraphStatus(settings.graph.to_s, graph_uuid)
        error(invalid_graph_status, status = 404) if status.nil?

        status 200
        return create_meta_json(status)
    end

    if config_times.is_something_running
      status 200
      return create_meta_json('still working')
    end

    # otherwise just check the status of the validations
    config_rules = config.get_rules

    # if there is a `keys` parameter
    # split up by ,
    # else or if the keys paramter was empty
    # get the keys from the rules config
    keys = []
    keys = params[:keys].split(',') if params[:keys]
    all_keys = keys.empty?
    keys = config_rules.keys if all_keys

    error(no_date_provided, status = 500) unless params[:date]
    error(no_timestamp_provided, status = 500) unless params[:time]
    time = (params[:date] + ' ' + params[:time]).to_s

    keys.each do |key|
        next unless config_rules.key?(key)
        # we skip returning a 'still working'
        # if this rule exists
        unless check_rule_existence_in_db(key, settings.graph.to_s, time)
            status 200
            return create_meta_json('still working')
        end
    end
    attributes = {
        'timestamp' => time
    }

    status 200
    return create_meta_json('finished', attributes)
end
