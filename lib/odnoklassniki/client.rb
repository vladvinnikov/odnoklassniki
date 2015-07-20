require_relative 'request'

module Odnoklassniki
  class Client

    def initialize(attrs= {})
      attrs = Odnoklassniki.options.merge(attrs)
      Config::VALID_OPTIONS_KEYS.each do |key|
        instance_variable_set("@#{key}".to_sym, attrs[key])
      end
      @refreshed = false
    end

    def get(method, params={}, &block)
      request_method(:get, method, params, block)
    end

    def post(method, params={}, &block)
      request_method(:post, method, params, block)
    end

    def refresh_token!
      @refreshed = true
      data = request.post('/oauth/token.do', refresh_credentials)
      @request = nil
      # @access_token = data['access_token']
    end

    private

    def fallback(params)
      [params.delete(:method), params]
    end

    def method_path(method)
      if method.start_with?('api')
        "/#{method}"
      elsif method.start_with?('/api')
        method
      elsif method.start_with?('/')
        "/api#{method}"
      else
        "/api/#{method}"
      end.gsub('.', '/')
    end

    def refresh_credentials
      {
        refresh_token: @access_token,
        grant_type:    'refresh_token',
        client_id:     @client_id,
        client_secret: @client_secret
      }
    end

    def request_method(http_method, method, params, block)
      method, params = fallback(method) if method.is_a?(Hash)
      response = request.send(http_method, method_path(method), params)
      response = block.call response if block
      response
    end

    def request
      refresh_token! unless @refreshed
      @request ||= Request.new(credentials)
    end

    def credentials
      {
        access_token:    @access_token,
        client_secret:   @client_secret,
        application_key: @application_key
      }
    end

  end
end
