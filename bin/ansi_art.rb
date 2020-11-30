#!/usr/bin/env ruby

require 'bundler/setup'

require 'nl/knd_client'

knd = NL::KndClient::SimpleKndClient.new
knd.open

d11 = knd.get_depth
d16 = NL::KndClient::Kinutils.unpack11_to_16_lut(d11)

knd.close

# img will contain full 3D coordinates after this, but we'll only use Z here.
# img[y][x] will return the voxel at (x, y) in the 640x480 data.
img = d16.unpack('S*').map { |v|
  NL::KndClient::Kinutils::DEPTH_LUT[v]
}.each_slice(640).map.with_index { |row, y|
  row.map.with_index { |zw, x|
    if zw > 4000
      {x: 0, y: 0, z: -1}
    else
      {
        x: NL::KndClient::Kinutils.xworld(x, zw),
        y: NL::KndClient::Kinutils.yworld(y, zw),
        z: zw
      }
    end
  }
}

puts img.each_slice(15).map(&:first).map { |z| z.each_slice(11).map(&:first) }.map { |z| z.map { |v| [0, v[:z] - 200].max / 450 } }.map { |z| z.map { |v| [".", '-', "\e[1m-\e[0m", 'o', "\e[1mo\e[0m", 'O', "\e[1mO\e[0m"].reverse[v] }.join }
