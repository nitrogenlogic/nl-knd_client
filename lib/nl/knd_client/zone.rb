module NL
  module KndClient
    # Represents a spatial zone from KND.
    class Zone < Hash
      # Switched to integer millimeters in version 2
      ZONE_VERSION = 2

      # TODO: This should be a constant, not a class variable
      @@param_names = {
        'occupied' => 'Occupied',

        'bright' => 'Brightness',

        'sa' => 'Surface Area',

        'xc' => 'X Center',
        'yc' => 'Y Center',
        'zc' => 'Z Center',

        'xmin' => 'World Xmin',
        'ymin' => 'World Ymin',
        'zmin' => 'World Zmin',
        'xmax' => 'World Xmax',
        'ymax' => 'World Ymax',
        'zmax' => 'World Zmax',

        'px_xmin' => 'Screen Xmin',
        'px_ymin' => 'Screen Ymin',
        'px_zmin' => 'Screen Zmin',
        'px_xmax' => 'Screen Xmax',
        'px_ymax' => 'Screen Ymax',
        'px_zmax' => 'Screen Zmax',

        'pop' => 'Population',
        'maxpop' => 'Max Population',

        'negate' => 'Inverted',
        'param' => 'Occupied Parameter',
        'on_level' => 'Rising Threshold',
        'off_level' => 'Falling Threshold',
        'on_delay' => 'Rising Delay',
        'off_delay' => 'Falling Delay',
      }.freeze

      @@name_params = @@param_names.invert.freeze

      # Merges with the other Hash or Zone, then converts known keys into
      # their expected types.
      def merge_zone other
        merge! other
        normalize! unless other.is_a? Zone
        self
      end

      # Initializes a zone definition with the given key-value set.  If
      # kvpairs is a string, it is parsed with kin_kvp().  If it is a Hash,
      # its keys are used as the zone definition.
      def initialize kvpairs, normalize=true
        EMKndClient.bench 'Zone.new' do
          super nil
          if kvpairs.is_a? String
            EMKndClient.bench 'Zone.new string' do
              merge! kvpairs.kin_kvp
              normalize = false
            end
          elsif kvpairs.is_a? Hash
            EMKndClient.bench 'Zone.new hash' do
              merge! kvpairs
            end
          else
            raise "kvpairs must be a String or a Hash, not #{kvpairs.class}."
          end
          normalize! if normalize
          self['occupied'] = (self['occupied'] == 1) if self['occupied'].is_a?(Fixnum)
        end
      end

      # Converts known keys into their expected types.
      def normalize!
        EMKndClient.bench 'Zone.normalize!' do
          if has_key?('version') && self['version'].to_i < 2
            EMKndClient.log "Converting version #{self['version']} zone to version #{ZONE_VERSION}"
            self['xmin'] &&= self['xmin'].to_f * 1000.0
            self['ymin'] &&= self['ymin'].to_f * 1000.0
            self['zmin'] &&= self['zmin'].to_f * 1000.0
            self['xmax'] &&= self['xmax'].to_f * 1000.0
            self['ymax'] &&= self['ymax'].to_f * 1000.0
            self['zmax'] &&= self['zmax'].to_f * 1000.0
          end

          self['xmin'] &&= self['xmin'].to_i
          self['ymin'] &&= self['ymin'].to_i
          self['zmin'] &&= self['zmin'].to_i
          self['xmax'] &&= self['xmax'].to_i
          self['ymax'] &&= self['ymax'].to_i
          self['zmax'] &&= self['zmax'].to_i
          self['px_xmin'] &&= self['px_xmin'].to_i
          self['px_ymin'] &&= self['px_ymin'].to_i
          self['px_zmin'] &&= self['px_zmin'].to_i
          self['px_xmax'] &&= self['px_xmax'].to_i
          self['px_ymax'] &&= self['px_ymax'].to_i
          self['px_zmax'] &&= self['px_zmax'].to_i
          self['pop'] &&= self['pop'].to_i
          self['maxpop'] &&= self['maxpop'].to_i
          self['xc'] &&= self['xc'].to_i
          self['yc'] &&= self['yc'].to_i
          self['zc'] &&= self['zc'].to_i
          self['sa'] &&= self['sa'].to_i
          self['bright'] &&= self['bright'].to_i

          if has_key? 'negate'
            if self['negate'] == 'true' then
              self['negate'] = true
            elsif self['negate'] == 'false' then
              self['negate'] = false
            elsif self['negate'].respond_to? 'to_i' then
              self['negate'] = self['negate'].to_i == 1 ? true : false
            else
              self['negate'] = !!self['negate']
            end
          end

          unless self.range('param').include?(self['param'])
            self.delete 'param'
          end

          self['on_level'] &&= self['on_level'].to_i
          self['off_level'] &&= self['off_level'].to_i
          self['on_delay'] &&= self['on_delay'].to_i
          self['off_delay'] &&= self['off_delay'].to_i

          if has_key? 'occupied' and self['occupied'].respond_to? 'to_i' then
            self['occupied'] = self['occupied'].to_i == 1 ? true : false
          end

          Zone.fix_name!(self['name']) if has_key? 'name'
        end

        self
      end

      # Computes the range for the given parameter.  Returns nil if param is
      # not a valid zone parameter, the parameter's range is unknown, or the
      # given parameter has no range.
      #
      # TODO: this should probably just be a constant Hash
      def range param
        case param
        when 'xmin', 'xmax'
          (-KNC_XMAX / 2)..(KNC_XMAX / 2)

        when 'ymin', 'ymax'
          (-KNC_YMAX / 2)..(KNC_YMAX / 2)

        when 'zmin', 'zmax'
          0..KNC_ZMAX

        when 'px_xmin', 'px_xmax'
          0..639

        when 'px_ymin', 'px_ymax'
          0..479

        when 'px_zmin', 'px_zmax'
          0..KNC_PXZMAX

        when 'pop'
          0..self['maxpop']

        when 'maxpop'
          0..(640 * 480)

        when 'xc'
          0..1000

        when 'yc'
          0..1000

        when 'zc'
          0..1000

        when 'sa'
          (self['xmax'] - self['xmin']) * (self['ymax'] - self['ymin'])

        when 'bright'
          0..1000

        when 'negate'
          [false, true]

        when 'param'
          ['pop', 'sa', 'bright', 'xc', 'yc', 'zc']

        when 'on_level', 'off_level'
          # TODO: Range depends on param
          -5000..(640 * 480)

        when 'on_delay', 'off_delay'
          0..(86400 * 30)

        else
          nil
        end
      end

      # Returns a hash mapping parameter names to their human-friendly names
      # (excludes the 'name' parameter).
      def self.params
        @@param_names
      end

      # Returns a hash mapping human-friendly names to parameter names.
      def self.names
        @@name_params
      end

      # Removes unsupported characters from the given name, modifying the string directly
      def self.fix_name! str
        # TODO: Support spaces (need to change HTML to use data-zone),
        # strip or error on non-UTF8 non-printable characters
        str.delete!(",")
        str.tr!(" \t\r\n", '_')
        str
      end
    end
  end
end
