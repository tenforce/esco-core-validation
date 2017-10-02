class FileHandler
    ###
    # Init, creates the rules and types
    # and fills them with data from the resource files
    ###
    def initialize
        @rules = {}
        @types = {}
        @dir = ''
    end

    ###
    # Reads the rules config file and stores it in the @rules variable
    ###
    def refresh_rules
        filepath = get_file_path('rules.json')
        @rules = read_file(filepath, 'validations')
    end

    ###
    # Reads the types config file and stores it in the @types variable
    #
    def refresh_types
        filepath = get_file_path('types.json')
        @types = read_file(filepath, 'types')
    end

    ###
    # Reads the file, parses the JSON and returns the value of the key
    # read ensures the file is closed before returning
    # http://ruby-doc.org/core-2.3.1/IO.html
    ###
    def read_file(path, key)
        file = IO.read(path)
        JSON.parse(file)[key]
    end

    ###
    # Refreshes the value of the @rules variable
    # and returns the copy of the @rules variable
    ###
    def get_rules
        refresh_rules
        @rules.clone
    end

    ###
    # Returns the copy of the @types variable
    ###
    def get_types
        refresh_types
        @types.clone
    end

    ###
    # Set the new dir variable
    ###
    def set_dir(new_dir)
        # checking for / at the end of the env variable
        new_dir = '' unless new_dir
        new_dir += '/' unless new_dir[-1, 1] == '/'
        @dir = new_dir
    end

    ###
    # Returns relative path to resource file
    ###
    def get_file_path(filename)
        # dir = File.realdirpath(File.join(File.dirname(__FILE__), '..', 'config'))
        File.join(@dir, filename)
    end
end
