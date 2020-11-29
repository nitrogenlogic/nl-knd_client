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
