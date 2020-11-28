require 'nl/fast_png'

module NL
  module KndClient
    # An asynchronous EventMachine-based client for KND, with full support for
    # all major KND features.
    #
    # There should only be a single global instance of this class at any given
    # time (TODO: bring class-level variables into a single instance).
    class EMKndClient
      @@logger = ->(msg) { puts "#{Time.now.iso8601(6)} - #{msg}" }
      @@bencher = nil

      # Sets a block to be called for any log messages generated by EMKndClient
      # and related classes.  The default is to print messages to STDOUT with a
      # timestamp.  Calling without a block will disable logging.
      def self.on_log(&block)
        @@logger = block
      end

      # Logs a message to STDOUT, or to the logging function specified by
      # .on_log.
      #
      # The KNC project this code was extracted from was written without
      # awareness of the Ruby Logger class.
      def self.log(msg)
        @@logger.call(msg) if @@logger
      end

      # Calls the given +block+ for certain named sections of code.  The
      # benchmark block must accept a name parameter and a proc parameter, and
      # call the proc.  Disables EMKndClient benchmarking if no block is given.
      # This is used by KNC to instrument
      def self.on_bench(&block)
        @@bencher = block
      end

      # Some EMKndClient functions call this method to wrap named sections of
      # code with optional instrumentation.  Use the .on_bench method to enable
      # benchmarking/instrumentation.
      def self.bench(name, &block)
        if @@bencher
          @@bencher.call(block)
        else
          yield
        end
      end

      include EM::Protocols::LineText2

      DEPTH_SIZE = 640 * 480 * 11 / 8
      VIDEO_SIZE = 640 * 480
      BLANK_IMAGE = NL::FastPng.store_png(640, 480, 8, "\x00" * (640 * 480))

      def self.blank_image
        BLANK_IMAGE
      end

      @@images = {
        :depth => BLANK_IMAGE,
        :linear => BLANK_IMAGE,
        :ovh => BLANK_IMAGE,
        :side => BLANK_IMAGE,
        :front => BLANK_IMAGE,
        :video => BLANK_IMAGE
      }

      @@connect_cb = nil

      @@connection = 0
      @@connected = false
      @@instance = nil

      # The time of the last connection/disconnection event
      @@connection_time = Time.now

      # Returns the most recent PNG of the given type, an empty string if no
      # data, or nil if an invalid type.
      def self.png_data type
        @@images[type]
      end

      def self.clear_images
        @@images.each_key do |k|
          @@images[k] = BLANK_IMAGE
        end
      end

      # Whether the client is connected to the knd server
      def self.connected?
        @@connected || false
      end

      # Sets or replaces a proc called with true or false when a connection
      # is made or lost.
      def self.on_connect &bl
        @@connect_cb = bl
      end

      def self.hostname
        @@hostname
      end

      def self.hostname= name
        @@instance.close_connection_after_writing if @@connected
        @@hostname = name
      end

      # Changes the current hostname and opens the connection loop.  If
      # connection fails, it will be retried automatically, so this should only
      # be called once for the application.
      def self.connect(hostname)
        self.hostname = hostname || '127.0.0.1'
        begin
          EM.connect(self.hostname, 14308, EMKndClient)
        rescue => e
          log e, 'Error resolving KND.'
          raise e
        end
      end

      # The currently-connected client instance.
      def self.instance
        @@instance if @@connected
      end

      def enter_depth
        @binary = :depth
        set_binary_mode(DEPTH_SIZE)
      end

      def enter_video(length = VIDEO_SIZE)
        @binary = :video
        set_binary_mode(length)
      end

      def leave_binary
        @binary = :none
      end

      def initialize
        super
        @@connection = @@connection + 1
        @thiscon = @@connection
        @binary = :none
        @quit = false
        @commands = []
        @active_command = nil
        @@connected ||= false
        @tcp_ok = false
        @tcp_connected = false

        @getbright_sent = false # Whether a getbright command is in the queue
        @depth_sent = false # Whether a getdepth command is in the queue
        @video_sent = false # Whether a getvideo command is in the queue
        @requests = {
          :depth => [],
          :linear => [],
          :ovh => [],
          :side => [],
          :front => [],
          :video => []
        }

        # The Mutex isn't necessary if all signaling takes place on the event loop
        @image_lock = Mutex.new

        # Zone/status update callbacks (for protocol plugins like xAP)
        @cbs = []
      end

      def connection_completed
        @tcp_connected = true

        log "Connected to depth camera server at #{EMKndClient.hostname} (connection #{@thiscon})."

        fps_proc = proc {
          do_command('fps') {|cmd|
            fps = cmd.message.to_i()
            if !@@connected && fps > 0
              log "Depth camera server is online (connection #{@thiscon})."

              @@connected = true
              @@connect_cb.call true if @@connect_cb

              now = Time.now
              elapsed = now - @@connection_time
              @@connection_time = now
              call_cbs :online, true, elapsed
            end

            $fps = fps
            call_cbs :fps, $fps

            @fpstimer = EM::Timer.new(0.3333333) do
              fps_proc.call
            end
          }.errback {|cmd|
            if cmd == nil
              log "FPS command timed out.  Disconnecting from depth camera server (connection #{@thiscon})."
            else
              log "FPS command failed: #{cmd.message}.  Disconnecting from depth camera server (connection #{@thiscon})."
            end
            close_connection
          }
        }
        zone_proc = proc {
          get_zones {
            # TODO: Unsubscribe and defer zones.json response response when
            # there is no web activity and xAP is off.
            @zonetimer = EM::Timer.new(2) do
              zone_proc.call
            end
          }
        }

        startup_proc = proc do
          fps_proc.call
          zone_proc.call
          subscribe().errback { |cmd|
            if cmd == nil
              log "Subscribe command timed out.  Disconnecting from depth camera server (connection #{@thiscon})."
            else
              log "Subscribe command failed: #{cmd.message}.  Disconnecting from depth camera server (connection #{@thiscon})."
            end
            close_connection
          }
        end

        do_command('ver') { |cmd|
          @version = cmd.message.split(' ', 2).last.to_i if cmd.message
          @fpstimer = EM::Timer.new(0.1, &startup_proc)
          log "Protocol version is #{@version}."
        }.errback { |cmd|
          if cmd == nil
            log "Version command timed out.  Disconnecting (connection #{@thiscon})."
            close_connection
          else
            log "Version command failed.  Assuming version 1."
            @version = 1
            @fpstimer = EM::Timer.new(0.1, &startup_proc)
          end
        }

        @@instance = self
      rescue => e
        log e
        Kernel.exit
      end

      def receive_line(data)
        # Send lines to any command waiting for data
        if @active_command
          @active_command = nil if @active_command.add_line data
          return
        end

        type, message = data.split(" - ", 2)

        case type
        when "DEPTH"
          enter_depth

        when 'VIDEO'
          length = message.gsub(/[^0-9 ]+/, '').to_i
          enter_video length

        when 'BRIGHT'
          line = message.kin_kvp
          name = Zone.fix_name! line['name']
          if $zones.has_key? name
            match = $zones[name]
            match['bright'] = line['bright'].to_i
            call_cbs :change, match
          else
            log "=== NOTICE - BRIGHT line for missing zone #{name}"
          end

        when "SUB"
          zone = Zone.new(message)
          name = zone["name"]
          if !$zones.has_key? name
            log "=== NOTICE - SUB added zone #{name} ==="
            $zones[name] = zone
            call_cbs :add, zone
          else
            match = $zones[name]
            match.merge_zone zone
            call_cbs :change, match
          end

        when "ADD"
          zone = Zone.new(message)
          name = zone["name"]
          $zones[name] = zone
          log "Zone #{name} added via ADD"
          call_cbs :add, zone

        when "DEL"
          name = message
          log "Zone #{name} removed via DEL"
          if $zones.include? message
            zone = $zones[message]
            $zones.delete message
            call_cbs :del, zone
          else
            puts "=== ERROR - DEL received for nonexistent zone ==="
          end

        when "OK"
          if @commands.length == 0
            puts "=== ERROR - OK when no command was queued - disconnecting ==="
            close_connection
          else
            cmd = @commands.shift
            active = cmd.ok_line message
            @active_command = cmd unless active
          end

        when "ERR"
          if @commands.length == 0
            puts "=== ERROR - ERR when no command was queued - disconnecting ==="
            close_connection
          end
          @commands.shift.err_line message

        else
          puts "----- Unknown Response -----"
          p data
        end
      end

      def receive_binary_data(d)
        case @binary
        when :depth
          EM.defer do
            data = d
            begin
              @image_lock.synchronize do
                @depth_sent = false
              end

              unpacked = nil

              if(check_requests(:front) or check_requests(:ovh) or check_requests(:depth) or
                  check_requests(:side) or check_requests(:linear))
                bench('unpack') do
                  unpacked = KinUtils.unpack11_to_16(data)
                end
              else
                raise "---- Received an unneeded depth image"
              end

              if check_requests(:depth)
                bench('16png') do
                  set_image :depth, NL::FastPng.store_png(640, 480, 16, unpacked)
                end
              end

              if check_requests(:linear)
                linbuf = nil
                bench('linear_plot') do
                  linbuf = KinUtils.plot_linear(unpacked)
                end
                bench('linear_png') do
                  set_image :linear, NL::FastPng.store_png(640, 480, 8, linbuf)
                end
              end

              if check_requests(:ovh)
                ovhbuf = nil
                bench('ovh_plot') do
                  ovhbuf = KinUtils.plot_overhead(unpacked)
                end
                bench('ovh_png') do
                  set_image :ovh, NL::FastPng.store_png(KNC_XPIX, KNC_ZPIX, 8, ovhbuf)
                end
              end

              if check_requests(:side)
                sidebuf = nil
                bench('side_plot') do
                  sidebuf = KinUtils.plot_side(unpacked)
                end
                bench('side_png') do
                  set_image :side, NL::FastPng.store_png(KNC_ZPIX, KNC_YPIX, 8, sidebuf)
                end
              end

              if check_requests(:front)
                frontbuf = nil
                bench('front_plot') do
                  frontbuf = KinUtils.plot_front(unpacked)
                end
                bench('front_png') do
                  set_image :front, NL::FastPng.store_png(KNC_XPIX, KNC_YPIX, 8, frontbuf)
                end
              end
            rescue => e
              log "Error in depth image processing task: #{e.to_s}"
              log "\t#{e.backtrace.join("\n\t")}"
            end
          end

        when :video
          EM.defer do
            data = d
            begin
              @image_lock.synchronize do
                @video_sent = false
              end

              unpacked = nil

              unless check_requests(:video)
                raise "---- Received an unneeded video image"
              end

              if d.bytesize != VIDEO_SIZE
                set_image :video, BLANK_IMAGE
                raise "---- Unknown video image format with size #{d.bytesize}; expected #{VIDEO_SIZE}"
              end

              bench('videopng') do
                set_image :video, NL::FastPng.store_png(640, 480, 8, data)
              end

            rescue => e
              log "Error in video image processing task: #{e.to_s}"
              log "\t#{e.backtrace.join("\n\t")}"
            end
          end
        end

        leave_binary
      end

      def unbind
        begin
          if @tcp_connected
            log "Disconnected from camera server (connection #{@thiscon})."
            @@connect_cb.call false if @@connect_cb

            if @@connected
              now = Time.now
              elapsed = now - @@connection_time
              @@connection_time = now
              call_cbs :online, false, elapsed
            end

            @cbs.clear
          end

          EMKndClient.clear_images

          @@connected = false
          $fps = 0
          @@instance = nil
          @fpstimer.cancel if @fpstimer
          @zonetimer.cancel if @zonetimer
          @imagetimer.cancel if @imagetimer
          @refreshtimer.cancel if @refreshtimer

          @commands.each do |cmd|
            cmd.err_line "Connection closed"
          end

          @requests.each do |k, v|
            v.each do |req|
              req.call @@images[k]
            end
          end

          if @quit
            EventMachine::stop_event_loop
          else
            EM::Timer.new(1) do
              EM.connect(@@hostname, 14308, EMKndClient)
            end
          end
        rescue => e
          log e
          Kernel.exit
        end
      end

      # Pass a string or a EMKndCommand, returns the EMKndCommand.  The block, if
      # any, will be used as a EMKndCommand success callback
      def do_command command, &block
        if command.is_a? EMKndCommand
          cmd = command
        else
          cmd = EMKndCommand.new command
        end

        if block != nil
          cmd.callback do |*args|
            block.call *args
          end
        end

        log "do_command #{cmd.to_s}" if debug_cmd?(cmd.name)
        send_data "#{cmd.to_s}\n"
        @commands << cmd
        cmd
      end

      # TODO: Could do a multi-command function by having all deferred
      # command methods return the command object used, throwing them in an
      # array, passing the array to do_multi_cmd, and do_multi_cmd adding its
      # own success/failure handlers to each command object.

      # Defers an update of the zone list.  This will run the zones command
      # to see if any zones have been removed.  The block will be called with
      # no parameters on success, if a block is given.
      def get_zones &block
        # No subscription received after this zone command finishes can
        # contain a zone that was removed prior to the execution of
        # this command
        do_command 'zones' do |cmd|
          bench('get_zones') do
            zonelist = {}
            cmd.lines.each do |line|
              zone = Zone.new line
              oldzone = $zones[zone['name']]
              zone['bright'] = oldzone['bright'] if oldzone && oldzone.include?('bright')
              zonelist[zone['name']] = zone
            end

            # Notify protocol plugin callbacks about new zones
            bench('get_zones_callbacks') do
              unless @cbs.empty?
                zonelist.each do |k, v|
                  if !$zones.include? k
                    log "Zone #{k} added in get_zones"
                    call_cbs :add, v
                  elsif v['occupied'] != $zones[k]['occupied']
                    log "Zone #{k} changed in get_zones"
                    call_cbs :change, v
                  end
                end
                $zones.each do |k, v|
                  if !zonelist.include? k
                    log "Zone #{k} removed in get_zones"
                    call_cbs :del, v
                  end
                end
              end
            end

            $zones = zonelist
            $occupied = cmd.message.gsub(/.*, ([0-9]+) occupied.*/, '\1').to_i if cmd.message
          end

          if block != nil
            block.call
          end
        end
      end

      # Subscribes to zone updates.  The given block will be called with a
      # success message on success.  The return value is the command object
      # that represents the subscribe command (e.g. for adding an errback).
      def subscribe &block
        do_command 'sub' do |cmd|
          block.call cmd.message if block != nil
        end
      end

      # Updates parameters on the given zone.  The zone argument should be a
      # Zone with only the changed parameters and zone name filled in.  The
      # changes will be merged with the existing zone data.  If xmin, ymin,
      # zmin, xmax, ymax, and zmax are all specified, then any other
      # attributes will be ignored.  Attributes will be set in the order they
      # are returned by iterating over the keys in zone.  The block, if
      # specified, will be called with true and a message for success, false
      # and a message for error.  If multiple parameters are set, messages
      # from individual commands will be separated by separator.
      def set_zone zone, separator="\n", &block
        zone = zone.clone

        name = zone['name']
        zone.delete 'name'
        if name == nil || name.length == 0
          if block != nil
            block.call false, "No zone name was given."
          end
          return
        end
        if !$zones.has_key? name
          if block != nil
            block.call false, "Zone #{name} doesn't exist."
          end
          return
        end

        all = ['xmin', 'ymin', 'zmin', 'xmax', 'ymax', 'zmax'].reduce(true) { |has, attr|
          has &= zone.has_key? attr
        }

        if all
          cmd = EMKndCommand.new 'setzone', name, 'all',
            zone['xmin'], zone['ymin'], zone['zmin'],
            zone['xmax'], zone['ymax'], zone['zmax']

          if block != nil
            cmd.callback { |cmd|
              $zones.has_key?(name) && $zones[name].merge_zone(zone)
              block.call true, cmd.message
            }
            cmd.errback {|cmd| block.call false, (cmd ? cmd.message : 'timeout')}
          end

          do_command cmd

          ['xmin', 'ymin', 'zmin', 'xmax', 'ymax', 'zmax'].each do |key|
            zone.delete key
          end
        end

        # Send values not covered by xmin/ymin/zmin/xmax/ymax/zmax combo above
        unless zone.empty?
          # TODO: Extract a multi-command method from this
          zone = zone.clone
          zone.delete 'name'

          if zone.length == 0
            if block != nil
              block.call false, "No parameters were specified."
            end
            return
          end

          result = true
          messages = []
          cmds = []
          count = 0
          func = lambda {|msg|
            messages << msg
            count += 1
            if block != nil and count == cmds.length
              block.call result, messages.join(separator)
            end
          }

          zone.each do |k, v|
            if v == true
              v = 1
            elsif v == false
              v = 0
            end
            cmd = EMKndCommand.new 'setzone', name, k, v
            cmd.callback { |cmd|
              $zones.has_key?(name) && $zones[name][k] = v
              func.call cmd.message
            }
            cmd.errback { |cmd|
              result = false
              func.call (cmd ? cmd.message : 'timeout')
            }
            cmds << cmd
          end
          cmds.each do |cmd| do_command cmd end
        end
      end

      # Adds a new zone.  Calls block with true and a message for success,
      # false and a message for error.
      def add_zone zone, &block
        zone['name'] ||= 'New_Zone'
        zone['name'].gsub!(/ +/, '_')
        zone['name'].gsub!(/[^A-Za-z0-9_]/, '')

        if zone['name'].downcase == '__status'
          block.call false, 'Cannot use "__status" for a zone name.'
        else
          add_zone2(zone['name'], zone['xmin'], zone['ymin'], zone['zmin'], zone['xmax'], zone['ymax'], zone['zmax']) {|*args|
            block.call *args if block != nil
          }
        end
      end

      # Adds a new zone.  Calls block with true and a message for success,
      # false and a message for error.
      def add_zone2 name, xmin, ymin, zmin, xmax, ymax, zmax, &block
        cmd = EMKndCommand.new 'addzone', name, xmin, ymin, zmin, xmax, ymax, zmax

        if block != nil
          cmd.callback { |cmd|
            block.call true, cmd.message
          }
          cmd.errback { |cmd|
            block.call false, (cmd ? cmd.message : 'timeout')
          }
        end

        do_command cmd
      end

      def remove_zone name, &block
        cmd = EMKndCommand.new 'rmzone', name

        if block != nil
          cmd.callback { |cmd|
            block.call true, cmd.message
          }
          cmd.errback { |cmd|
            block.call false, (cmd ? cmd.message : 'timeout')
          }
        end

        do_command cmd
      end

      def clear_zones &block
        cmd = EMKndCommand.new 'clear'

        if block != nil
          cmd.callback { |cmd|
            block.call true, cmd.message
          }
          cmd.errback { |cmd|
            block.call false, (cmd ? cmd.message : 'timeout')
          }
        end

        do_command cmd
      end

      def request_brightness &block
        return if @getbright_sent

        cmd = EMKndCommand.new 'getbright'

        cmd.callback { |cmd|
          block.call true, cmd.message if block
          @getbright_sent = false
        }
        cmd.errback { |cmd|
          block.call false, (cmd ? cmd.message : 'timeout') if block
          @getbright_sent = false
        }

        @getbright_sent = true
        do_command cmd
      end

      # Makes sure a getdepth or getvideo command is queued as appropriate
      def request_image type
        if type == :video
          do_command 'getvideo' unless @video_sent
          @video_sent = true
        else
          do_command 'getdepth' unless @depth_sent
          @depth_sent = true
        end
      end
      private :request_image

      # Returns true if there are requests pending of the given type
      def check_requests type
        ret = nil
        bench("check_requests #{type}") do
          @image_lock.synchronize do
            ret = !@requests[type].empty?
          end
        end
        return ret
      end

      # Sets the PNG data for the given type of image
      def set_image type, pngdata
        @image_lock.synchronize do
          @@images[type] = pngdata
          reqs = @requests[type].clone
          EM.next_tick do
            reqs.each do |v|
              v.call pngdata
            end
          end
          @requests[type].clear
        end
      end
      private :set_image

      # The parameter is the type of image to request (:depth, :linear, :ovh,
      # :side, :front, or :video).  The given block will be called with a
      # string containing the corresponding PNG data, or an empty string.
      def get_image type, &block
        raise "Invalid image type: #{type}" if @requests[type] == nil

        @image_lock.synchronize do
          if @requests[type].empty?
            request_image type
          end
          if block_given?
            @requests[type].push block
          else
            @requests[type].push proc { }
          end

          length = @requests[type].length
          log "There are now #{length} #{type} requests." if $benchmark && length > 1
        end
      end

      # Adds a callback to be called when a zone is added, removed, or
      # changed, the framerate changes, or the system disconnects.
      #
      # For zone updates, the given block/proc/lambda will be called with the
      # type of operation (:add, :del, :change) and the Zone object.
      #
      # For status updates, the block/proc/lambda will be called with the
      # status value being updated (:online, :fps) the value (true/false
      # for :online, 0-30 for :fps), and for :online, the number of seconds
      # since the last online/offline transition.
      #
      # The block will be called with :fps and :add events as soon as it is
      # added, and an :online event if already online.
      def add_cb block
        raise 'Parameter must be callable' unless block.respond_to? :call
        unless @cbs.include? block
          @cbs << block
          block.call :online, @@connected, (Time.now - @@connection_time) if $fps > 0
          block.call :fps, $fps
          $zones.each do |k, v|
            block.call :add, v
          end
        end
      end

      # Removes a zone callback previously added with add_zone_cb.  The block
      # will be called with :online, false when it is removed.
      def remove_cb block
        raise 'Parameter must be callable' unless block.respond_to? :call
        @cbs.delete block
        block.call :online, false, (Time.now - @@connection_time)
      end

      # Calls each callback with the given arguments.
      def call_cbs *args
        @cbs.each do |cb|
          cb.call *args
        end
      end
      private :call_cbs
    end
  end
end
