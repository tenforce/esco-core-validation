class TimeHandler
    ###
    # Init, creates timestamps, and difference (in seconds)
    # sets the timestamp for each rule
    ###
    def initialize(rules)
        rule_keys = rules.keys
        @timestamps = {}
        @difference = 60*30

        rule_keys.each do |key|
            @timestamps[key] = {
                'latest_run' => nil,
                'is_running' => false
            }
        end
    end

    ###
    # if a rule_key is is not part of the timestamps
    # -> the config file changed in the meantime!!!
    # create a new timestamp for that rule
    # return the latest timestamp
    ###
    def get_latest(rule_key)
        unless @timestamps.key?(rule_key)
          @timestamps[rule_key] = {
              'latest_run' => nil,
              'is_running' => false
          }
        end
        @timestamps.fetch(rule_key).fetch('latest_run')
    end

    ###
    # check if a rule can run again
    # if so, return true
    # else return the number of seconds until the next run
    ###
    def can_run_again(rule_key, now)
        ## converting it to seconds
        now = Time.parse(now).to_i
        latest = @timestamps.fetch(rule_key).fetch('latest_run')
        return true if latest == nil
        latest = Time.parse(latest).to_i

        # return true if the difference is at least 30 minutes
        if (now-latest) >= @difference
          return true
        end
        return  @difference - (now - latest)
    end

    ###
    # set the latest_run timestamp of a rule_key
    ###
    def set_latest(rule_key, timestamp)
        @timestamps[rule_key]['latest_run'] = timestamp
    end

    ###
    # set the running status of a rule_key
    ###
    def set_running(rule_key, status)
        @timestamps[rule_key]['is_running'] = status
    end

    ###
    # check if something is running now in the db now
    ###
    def is_something_running
        @timestamps.each_value do |timestamp|
            return true if timestamp.fetch('is_running') == true
        end
        false
    end
end
