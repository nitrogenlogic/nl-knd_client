require 'mkmf'
extension_name='kinutils'

raise 'libnlutils not found' unless have_library("nlutils", "nl_unescape_string")

with_cflags("#{$CFLAGS} -O3 -Wall -Wextra #{ENV['EXTRACFLAGS']} -std=c99 -D_XOPEN_SOURCE=700 -D_ISOC99_SOURCE -D_GNU_SOURCE") do
  create_makefile('nl/knd_client/kinutils')
end
