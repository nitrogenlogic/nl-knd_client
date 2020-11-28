module NL
  module KndClient
    # Represents a deferred KND command run by the EventMachine-based client,
    # EMKndClient.  Callbacks will be called with the EMKndCommand object as
    # their sole parameter.
    class EMKndCommand
      include EM::Deferrable
      attr_reader :linecount, :lines, :name, :message

      # Reads command debugging configuration from the KNC_DEBUG_CMD
      # environment variable.  Called automatically by .debug_cmd?.
      def self.init_debug_cmd
        dbg = ENV['KNC_DEBUG_CMD']

        case dbg
        when 'true'
          @@debug_cmd = true

        when 'false'
          @@debug_cmd = false

        when String
          @@debug_cmd = dbg.split(',').map(&:strip)

        else
          @@debug_cmd = false
        end
      end

      # Returns true if the given command should have debugging info logged.
      def self.debug_cmd?(cmdname)
        init_debug_cmd if @@debug_cmd.nil?
	@@debug_cmd == true || (@@debug_cmd.is_a?(Array) && @@debug_cmd.include?(cmdname))
      end

      # Initializes a deferred 'name' command, removing commas from arguments
      # (KND command arguments cannot contain commas)
      def initialize(name, *args)
        @name = name
        @args = args
        @argstring = (args.length > 0 && " #{@args.map {|s| s.to_s.gsub(',', '') if s != nil }.join(',')}") || ''
        @linecount = 0
        @lines = []
        @message = ""

        timeout 10

        log "Command #{@name} Initialized" if EMKndCommand.debug_cmd?(@name)
      end

      # Called by EMKndClient when a success line is received
      # Returns true if the command is done, false if lines are needed
      def ok_line(message)
        @message = message

        log "Command #{@name} OK - #{message}" if EMKndCommand.debug_cmd?(@name)

        case @name
        when "zones", "help"
          @linecount = message.to_i
        end

        if @linecount == 0
          succeed self
          return true
        end

        return false
      end

      # Called by EMKndClient when an error line is received
      def err_line(message)
        @message = message

        log "Command #{@name} ERR - #{message}" if EMKndCommand.debug_cmd?(@name)

        fail self
      end

      # Called by EMKndClient to add a line
      # Returns true when enough lines have been received
      def add_line(line)
        lines << line
        @linecount -= 1
        if @linecount == 0
          succeed self
        end
        return @linecount == 0
      end

      # Converts the command to a string formatted for sending to knd.
      def to_s
        "#{@name}#{@argstring}"
      end

      private

      def log(msg)
        EMKndClient.log(msg)
      end
    end
  end
end
