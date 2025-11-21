# frozen_string_literal: true

# This module is for adding factet.conf entries in the configuration file.
module Facter::Util
  require 'fileutils'

# Provides utilities for managing the Facter configuration file, including ensuring its existence,
# adding TTLs for facts.
# Class that represents a fact cache
  class Factercache
    def initialize(name, validity_seconds, on_changed = '', on_changed_type = :string)
      @name             = name
      @validity_seconds = validity_seconds
      @on_changed_val   = ''

      ensure_file
      puppetapplycmdttl(@name, @validity_seconds)
    end
    def file_path
      Puppet.settings[:config].gsub(/puppet.puppet.conf$/, 'facter/facter.conf')
    end
    def ensure_file
      return if File.exist?(file_path)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, default_content)
    end
    private
    def puppetapplycmdttl(name, validation_seconds)
      `mkdir -p -m 0644 $(dirname #{file_path} )  && #{  Puppet.settings[:vardir].gsub(/cache$/, 'bin')        }/puppet resource pe_hocon_setting  '#{name}' path=#{file_path}  ensure=present value='#{validation_seconds} seconds' type=string`
    end
  end
end






