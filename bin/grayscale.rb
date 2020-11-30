#!/usr/bin/env ruby
# Displays live depth data as a grayscale range using SimpleKndClient.
# Requires a truecolor-capable terminal.
#
# (C)2020 Mike Bourgeous

require 'bundler/setup'

require 'nl/knd_client'

begin
  knd = NL::KndClient::SimpleKndClient.new
  knd.open

  STDOUT.write "\e[H\e[J"

  loop do
    d11 = knd.get_depth
    d8 = NL::KndClient::Kinutils.plot_linear(NL::KndClient::Kinutils.unpack11_to_16(d11))

    # img will contain full 3D coordinates after this, but we'll only use Z here.
    # img[y][x] will return the voxel at (x, y) in the 640x480 data.
    img = d8.bytes.each_slice(640).to_a

    chars = img.each_slice(15).map(&:first).map { |z|
      z.each_slice(11).map(&:first)
    }.map { |z|
      z.map { |v|
        gray = [v - 150, 0].max * 2
        "\e[0;37;48;2;#{gray};#{gray};#{gray}m "
      }.join
    }

    puts chars

    STDOUT.write "\e[H"
  end
ensure
  knd&.close
  puts "\e[45H\e[0m"
end
