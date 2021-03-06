require 'net/smtp'
require 'core_ext/module/async'

module Travis
  module Notifications
    class Email
      EVENTS = 'build:finished'

      include Logging

      def notify(event, object, *args)
        ActiveSupport::Notifications.instrument('notify', :target => self, :args => [event, object, *args]) do
          send_emails(object) if object.send_email_notifications?
        end
      end
      async :notify if ENV['RAILS_ENV'] != 'test'

      protected

        def send_emails(object)
          email(object).deliver
        rescue Errno::ECONNREFUSED, Net::SMTPError => e
          puts e.message, e.backtrace
        end

        def email(object)
          mailer(object).send(:"#{object.state}_email", object, object.email_recipients)
        end

        def mailer(object)
          Travis::Mailer.const_get(object.class.name.gsub('Travis::Model::', ''))
        end
    end
  end
end
