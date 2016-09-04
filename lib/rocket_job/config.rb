require 'yaml'
# encoding: UTF-8
module RocketJob
  # Centralized Configuration for Rocket Jobs
  class Config
    include Plugins::Document

    # Returns the single instance of the Rocket Job Configuration for this site
    # in a thread-safe way
    def self.instance
      @@instance ||= begin
        first || create
      rescue StandardError
        # In case another process has already created the first document
        first
      end
    end

    # Useful for Testing, not recommended elsewhere.
    # When enabled all calls to `perform_later` will be redirected to `perform_now`.
    # Also, exceptions will be raised instead of failing the job.
    cattr_accessor(:inline_mode) { false }

    # The maximum number of worker threads to create on any one worker
    field :max_worker_threads, type: Integer, default: 10

    # Number of seconds between heartbeats from Rocket Job Worker processes
    field :heartbeat_seconds, type: Integer, default: 15

    # Maximum number of seconds a Worker will wait before checking for new jobs
    field :max_poll_seconds, type: Integer, default: 5

    # Number of seconds between checking for:
    # - Jobs with a higher priority
    # - If the current job has been paused, or aborted
    #
    # Making this interval too short results in too many checks for job status
    # changes instead of focusing on completing the active tasks
    #
    # Note:
    #   Not all job types support pausing in the middle
    field :re_check_seconds, type: Integer, default: 60

    # Change the RocketJob store
    def self.store_in(options)
      super
      Worker.store_in(options)
      Job.store_in(options)
      DirmonEntry.store_in(options)
    end

    # Configure Mongoid
    def self.load!(environment = 'development', file_name = nil, encryption_file_name = nil)
      config_file = file_name ? Pathname.new(file_name) : Pathname.pwd.join('config/mongo.yml')
      if config_file.file?
        logger.debug "Reading MongoDB configuration from: #{config_file}"
        Mongoid.load!(config_file, environment)
      else
        raise(ArgumentError, "Mongo Configuration file: #{config_file.to_s} not found")
      end

      # Load Encryption configuration file if present
      if defined?(SymmetricEncryption)
        config_file = encryption_file_name ? Pathname.new(encryption_file_name) : Pathname.pwd.join('config/symmetric-encryption.yml')
        if config_file.file?
          logger.debug "Reading SymmetricEncryption configuration from: #{config_file}"
          SymmetricEncryption.load!(config_file.to_s, environment)
        end
      end
    end

  end
end
