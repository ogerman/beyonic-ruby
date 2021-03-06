module Beyonic::AbstractApi
  class ApiError < StandardError
  end

  module ClassMethods

    def set_endpoint_resource(resource)
      @endpoint_url = Beyonic.endpoint_base + resource
    end

    def create(payload = {})
      resp = RestClient.post(@endpoint_url, payload, headers)
      self.new(Oj.load(resp))
    rescue RestClient::BadRequest => e
      raise ApiError.new(Oj.load(e.response.body))
    end

    def list(payload = {})
      # Turn payload into query parameters
      require "addressable/uri"
      uri = Addressable::URI.new
      uri.query_values = payload

      resp = RestClient.get(@endpoint_url + '?' + uri.query, headers)
      Oj.load(resp).map { |obj_attrs| self.new(obj_attrs)}
    end

    def get(id)
      resp = RestClient.get("#{@endpoint_url}/#{id}", headers)
      self.new(Oj.load(resp))
    end

    def update(id, payload)
      resp = RestClient.patch("#{@endpoint_url}/#{id}", payload, headers)
      self.new(Oj.load(resp))
      rescue RestClient::BadRequest => e
        raise ApiError.new(Oj.load(e.response.body))
    end

    def delete(id)
      resp = RestClient.delete("#{@endpoint_url}/#{id}", headers)
      return true if resp == ""
    end

    private

    def headers
      headers_hash = {}
      headers_hash.merge!({"Authorization" => "Token #{Beyonic.api_key}"}) if Beyonic.api_key
      headers_hash.merge!({"Beyonic-Version" => Beyonic.api_version}) if Beyonic.api_version
      headers_hash
    end
    
  end
  
  module InstanceMethods

    def save
      if respond_to?(:id) && !id.nil?
        self.class.update(id, to_h)
      else
        self.class.create(to_h)
      end
    end


    def []=(name, value)
      if name.to_sym == :id
        self.id=(value)
      else
        super(name,value)
      end
    end
    
  end

  module Initializer
    def initialize(*args)
      super(*args)
      #We should define it after Object initialization
      define_singleton_method(:id=) do |val|
        raise "Can't change id of existing #{self.class}"
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
    receiver.send :prepend, Initializer
  end

end