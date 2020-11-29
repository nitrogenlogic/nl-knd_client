require 'socket'

module NL
  module KndClient
    # A simple KND client that uses a background thread for I/O and works
    # without EventMachine.  This client does not (yet) support all of KND's
    # features.
    class SimpleKndClient
      def initialize(host: 'localhost', port: 14308)
        @host = host
        @port = 14308

        @callbacks = {}
        @zones = {}
      end

      # Calls the given block with the current full state of a zone, the type of
      # command received for a zone, and the updates for the zone.  '! DEPTH' is a
      # special zone name for depth images [HACK].
      def on_zone(name, &block)
        @callbacks[name] ||= []
        @callbacks[name] << block
      end

      # Removes the given callback from the given zone name.  '! DEPTH' is a
      # special zone name for depth images [HACK].
      def remove_callback(name, &block)
        @callbacks[name]&.delete(block)
      end

      # Connect to KND.
      def open
        @socket = TCPSocket.new(@host, @port)
        @run = true
        @t = Thread.new do read_loop end
        @socket.puts('sub')
      end

      # Close the connection to KND and stop the background thread.
      def close
        @run = false
        @t&.wakeup
        @t&.kill
        @socket&.close
        @t = nil
        @socket = nil
      end

      # Waits for and then returns depth data.
      def get_depth
        data = nil
        t = Thread.current

        cb = ->(d) { data = d; t.wakeup }
        on_zone('! DEPTH', &cb)

        @socket.puts('getdepth')
        sleep(1)

        raise "Data wasn't set within 1 second" if data.nil?

        data
      ensure
        remove_callback('! DEPTH', &cb)
      end

      private

      def read_loop
        while @run do
          line = @socket.readline

          begin
            type = line.split(' - ', 2).first

            case type
            when 'DEL', 'OK'
              next

            when 'DEPTH'
              num_bytes = line.gsub(/\A[^0-9]*(\d+)[^0-9]*\z/, '\1').to_i
              puts "\n\n\n\n\e[1;33m=========== DEPTH line #{num_bytes} ============\n\n\n\n"
              data = @socket.read(num_bytes)
              @callbacks['! DEPTH']&.each do |cb|
                cb.call(data) rescue puts "Error calling depth callback: #{MB::Sound::U.syntax($!.inspect)}"
              end

            else
              kvp = line.kin_kvp(symbolize_keys: true)
              name = kvp[:name] || (raise "No zone name was found")
              @zones[name] ||= {}
              @zones[name].merge!(kvp)

              @callbacks[kvp[:name]]&.each do |cb|
                cb.call(@zones[name]) rescue puts "Error calling callback: #{MB::Sound::U.syntax($!)}\n\t#{MB::Sound::U.syntax($!.backtrace.join("\n\t"))}"
              end
            end

          rescue => e
            puts "Error parsing line '#{line}': #{MB::Sound::U.syntax(e)}"
          end
        end
      end
    end
  end
end
