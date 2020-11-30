# NL::KndClient

Client library for interacting with the Nitrogen Logic [KND][0] (Kinematic
Network Daemon) server, which provides zone-based data from a Kinect.

There are two clients provided:

- `NL::KndClient::EMKndClient` &ndash; a complex, older, but full-featured
  asynchronous client based on EventMachine.  This is only available if the
  EventMachine gem is already present in your application's dependencies.
- `NL::KndClient::SimpleKndClient` &ndash; a simple, newer, quick-and-dirty
  `Thread`-based client that is easier to use, but does not support all KND
  features.

Some data decoding functions are also provided as a C extension in
`NL::KndClient::Kinutils`.

## License

NL::KndClient is &copy;2011-2020 Mike Bourgeous.

NL::KndClient is licensed under the Affero GPL version 3 (AGPLv3).  Feel free
to get in touch if you would like to discuss more permissive terms.


## Installation

This gem depends on the Nitrogen Logic C utility library, [nlutils][1].

After installing nlutils, add this line to your application's Gemfile:

```ruby
gem 'nl-knd_client', git: 'git@github.com:nitrogenlogic/nl-knd_client.git'
```

And then execute:

```bash
$ bundle install
```

## Usage

TODO: Write usage instructions here

### Quick and dirty ASCII/ANSI art

```ruby
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
```

```
-----------.......................---------------O--------O
-----------.....................--------------------------O
-----------.......OOOO.O........--------------------------O
-----O-----.......OOoooo........--------------------------O
-----------......OOOoooo.o......-OOoooo-------------------O
----O------......OOOOooooo.....OOoooooooo-----------------O
-----------.......OOoOooo......Oooooooooo-------------OOOOO
-----------.......OOOOOo.......Ooooooooo-------------OOOOOO
-----------........OOooo.......Ooooooooo-------------OOOOOO
-----------....--..OOooo........Oooooooo-------------OOOOOO
-----------...---...OOooo.......Ooooooo--------------OOOOOO
-----------...----..OOooo....Oooooooooo--------------OOOOOO
-----------.........OOooo.Oooooooooooooooooo---------OOOOOO
-----------.........OOooooOOoooooooooooooooooooo--OO-OOOOOO
-----------.........OOOoooooooooooooooooooooooooooooooOOOOO
-----------.........OOOooooooooooooooooooo-oo-oooooooooOOOO
-----------.........OOOooooooooooooooooooo--------OOOOOOOOO
-----------.---.O...OOOOooooOoooooooooooooo-----OOooOOOOOOO
----------------------------OOooooooooooooooo--OOOOOOOOOOOO
oo---------------------------OooooooooooooooOOOOOOOOOOOOOOO
ooo--------------------------OoooooooooooooOOOOOOOOOOOOOOOO
oooo--------------------------OooooooooOOOOOOOOOOOOOOOOOOOO
ooooo-----------------OOO-O--OOoooooooOOOOOOOOOOOOOOOOOOOOO
ooooo---------OO-oo-----O-----OooooOOOOOOOOOOOOOOOOOOOOOOOO
ooooo----OOOooooooo-----OOO--OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
oooOOOOooooooooooooo--O-OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
oOooooooooooooooooo---O-OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
oooooooooooooooo-----OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
oooooooooooooo----OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
ooooooooooo---OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
ooooooo-----OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
ooooo----OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
```

### Standalone command-line processing

There is a Makefile in the `ext/` directory that will build standalone tools
for unpacking and projecting raw depth data.

```bash
cd ext/
make

cat depth11.raw | ./unpack -i | ./overhead | convert -size 500x500 -depth 8 GRAY:- /tmp/overhead.png
```

[0]: https://github.com/nitrogenlogic/knd
[1]: https://github.com/nitrogenlogic/nlutils
