if FACEBOOKER_RAILS_PRE_2_3_0
  module ActionController
    # TODO: Removed in Rails 2.3.0. Leaving this is probably benign, but we might
    #       want to conditionally evaluate this based on the Rails version,
    class CgiRequest
      alias :initialize_aliased_by_facebooker :initialize

      def initialize(cgi, session_options = {})
        initialize_aliased_by_facebooker(cgi, session_options)
        @cgi.instance_variable_set("@request_params", request_parameters.merge(query_parameters))
      end
    
      DEFAULT_SESSION_OPTIONS[:cookie_only] = false
    end 
  end

  module ActionController
    class RackRequest < Request #:nodoc:
      alias :initialize_aliased_by_facebooker :initialize

      def initialize(cgi, session_options = {})
        initialize_aliased_by_facebooker(cgi, session_options)
        @cgi.instance_variable_set("@request_params", request_parameters.merge(query_parameters))
      end
    end 
  end
end

class CGI  
  class Session
    private
      alias :initialize_aliased_by_facebooker :initialize
      attr_reader :request, :initialization_options

      def initialize(request, option={})
        @request = request
        @initialization_options = option
        option['session_id'] ||= set_session_id
        initialize_aliased_by_facebooker(request, option)
      end
      
      def set_session_id
        if session_key_should_be_set_with_facebook_session_key? 
          request_parameters[facebook_session_key]
        else 
          request_parameters[session_key]
        end
      end

      def request_parameters
        request.instance_variable_get("@request_params")
      end

      def session_key_should_be_set_with_facebook_session_key?
        request_parameters[session_key].blank? && !request_parameters[facebook_session_key].blank?
      end

      def session_key
        initialization_options['session_key'] || '_session_id'
      end

      def facebook_session_key
        'fb_sig_session_key'
      end

      # TODO: Make sure this is correct. There's no create_new_id in Rails 2.3.0, but
      #       we might need to hook into some other method instead.
      if FACEBOOKER_RAILS_PRE_2_3_0
        alias :create_new_id_aliased_by_facebooker :create_new_id

        def create_new_id
          @new_session = true
          @session_id || create_new_id_aliased_by_facebooker
        end
      end
  end
end