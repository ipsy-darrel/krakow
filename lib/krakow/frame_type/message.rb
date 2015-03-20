require 'krakow'

module Krakow
  class FrameType
    # Message received from server
    class Message < FrameType

      # @return [Float] time of message instance creation
      attr_reader :instance_stamp
      attr_accessor :origin, :connection

      # @!group Attributes

      # @!macro [attach] attribute
      #   @!method $1
      #     @return [$2] the $1 $0
      #   @!method $1?
      #     @return [TrueClass, FalseClass] truthiness of the $1 $0
      attribute :attempts, Integer, :required => true
      attribute :timestamp, Integer, :required => true
      attribute :message_id, String, :required => true
      attribute :message, String, :required => true

      # @!endgroup

      def initialize(*args)
        super
        @instance_stamp = Time.now.to_f
      end

      # Message content
      #
      # @return [String]
      def content
        message
      end

      # @return [Krakow::Consumer]
      def origin
        unless(@origin)
          error 'No origin has been specified for this message'
          abort Krakow::Error::OriginNotFound.new('No origin specified for this message')
        end
        @origin
      end

      # @return [Krakow::Connection]
      def connection
        unless(@connection)
          error 'No origin connection has been specified for this message'
          abort Krakow::Error::ConnectionNotFound.new('No connection specified for this message')
        end
        @connection
      end

      # Proxy to [Krakow::Consumer#confirm]
      def confirm(*args)
        validate!
        origin.confirm(*[self, *args].compact)
      end
      alias_method :finish, :confirm

      # Proxy to [Krakow::Consumer#requeue]
      def requeue(*args)
        validate!
        origin.requeue(*[self, *args].compact)
      end

      # Proxy to [Krakow::Consumer#touch]
      def touch(*args)
        validate!
        result = origin.touch(*[self, *args].compact)
        @instance_stamp = Time.now.to_f
        result
      end

      # @return [NilClass]
      # @raises [Error::MessageTimeout]
      def validate!
        if(((Time.now.to_f - instance_stamp) * 1000) > connection.endpoint_settings[:msg_timeout].to_f)
          raise Krakow::Error::MessageTimeout.new "Message has exceeded allowed timeout (#{connection.endpoint_settings[:msg_timeout].to_f * 1000}s)"
        end
      end

    end
  end
end
