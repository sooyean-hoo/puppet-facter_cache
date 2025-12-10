# frozen_string_literal: true

# This module is for adding factet.conf entries in the configuration file.
module Facter::Util
  require 'fileutils'
  require 'hocon'

  # Provides utilities for managing the Facter configuration file, including ensuring its existence,
  # adding TTLs for facts.
  # Class that represents a fact cache
  class Factercache
    def initialize(name, validity_seconds, _on_changed = '', _on_changed_type = :string)
      @name             = name
      @validity_seconds = validity_seconds
      @on_changed_val   = ''

      ensure_file
      puppetapplycmdttl(@name, @validity_seconds)
    end

    def file_path
      Puppet.settings[:config].gsub(%r{puppet.puppet.conf$}, 'facter/facter.conf')
    end

    def ensure_file
      return if File.exist?(file_path)
      default_content = <<-FACTERCONF
        facts: {
        }
        FACTERCONF
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, default_content)
    end

    private

    def puppetapplycmdttl(name, validation_seconds)
      `mkdir -p -m 0644 $(dirname #{file_path}`
      facter_conf = Hocon.load(file_path)
      facter_conf['facts'] = { 'ttls' => [] } if facter_conf['facts'].nil?
      facter_conf['facts']['ttls'] = [] if facter_conf['facts']['ttls'].nil?
      facter_conf['facts']['ttls'] += [ {  name => "#{validation_seconds} seconds" } ]

      puppetcode = <<-PUPPETCODE
      $facts_ttls=#{facter_conf['facts']['ttls']}
      hocon_setting { 'facter_conf.facts.ttls':
        ensure  => present,
        path    => '#{file_path}',
        setting => 'facts.ttls',
        type    => 'array',
        value   => $facts_ttls,
      }
      PUPPETCODE
      cmd = "#{Puppet.settings[:vardir].gsub(%r{cache$}, 'bin')}/puppet apply"
      Open3.popen3(cmd) do |stdin, _stdout, _stderr, _wait|
        stdin.puts(puppetcode)
        stdin.close
        # stdout.read
      end
    end
  end
end
