require "nl/knd_client/version"

module NL
  module KndClient
  end
end

require_relative 'knd_client/kinutils'

begin
  require 'eventmachine'
rescue LoadError
  # Ignore missing eventmachine gem
end

if defined?(EM)
  require_relative('knd_client/em_knd_command')
  require_relative('knd_client/em_knd_client')
end
