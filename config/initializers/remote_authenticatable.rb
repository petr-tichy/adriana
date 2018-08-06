module Devise
  module Strategies
    class RemoteAuthenticatable < Authenticatable
      #
      # For an example check : https://github.com/plataformatec/devise/blob/master/lib/devise/strategies/database_authenticatable.rb
      #
      # Method called by warden to authenticate a resource.
      #
      def authenticate!
        #
        # authentication_hash doesn't include the password
        #

        puts "AUTH"

        # return custom!("/authfail") unless request.headers['REMOTE_USER'].present?

        auth_params = request.headers['REMOTE_USER']
        auth_params = 'petr.tichy@gooddata.com' unless auth_params.present?

        #
        # mapping.to is a wrapper over the resource model
        #
        resource = mapping.to.new

        return fail! unless resource

        # remote_authentication method is defined in Devise::Models::RemoteAuthenticatable
        #
        # validate is a method defined in Devise::Strategies::Authenticatable. It takes
        # a block which must return a boolean value.
        #
        # If the block returns true the resource will be loged in
        # If the block returns false the authentication will fail!
        #
        if validate(resource) { resource.remote_authentication(auth_params) }
          success!(resource)
        end
      end
      def valid?
        true
      end
    end
  end
end

# module Devise
#   module Models
#     module RemoteAuthenticatable
#       extend ActiveSupport::Concern
#
#       module ClassMethods
#         def serialize_from_session(id)
#           resource = self.new
#           resource.id = id
#           resource
#         end
#
#         def serialize_into_session(record)
#           [record.id]
#         end
#
#       end
#     end
#   end
# end


module Devise
  module Models
    module RemoteAuthenticatable
      extend ActiveSupport::Concern

      def remote_authentication(authentication_hash)
        puts "remote_authentication #{authentication_hash}"
        # Your logic to authenticate with the external webservice
        true
      end
    end
  end
end

Devise.add_module(:remote_authenticatable, {
    route: :session,
    strategy: true,
    controller: :sessions,
    model: 'devise/models/remote_authenticatable'
})
