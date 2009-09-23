# -*- coding: utf-8 -*-
require 'net/http'
Net::HTTP.version_1_2


class TomcatManager

  class TomcatManager::Unauthorized < Exception; end
  class TomcatManager::WarNotFound < Exception
    def initlalized(filename)
      super("war file not found : #{filename}")
    end
  end

  attr_accessor :manager
  attr_accessor :password
  attr_accessor :host
  attr_accessor :port

  def initialize 
    @host = "127.0.0.1"
    @port = "8080"
    yield self if block_given?
  end
  
  def list
    result = []
    request('/manager/list').body.each_line do |line|
      next if line =~ /^OK/
      e = line.split(/:/)
      result << { 
        :path => e[0],
        :status => e[1],
        :session => e[2],
        :name => e[3],
      }
    end
    
    result
  end

  def undeploy path
    response = request("/manager/undeploy?path=/#{path}")
    puts response.body
  end

  def deploy filename, path=nil
    raise WarNotFound.new(filename) unless File.exists?(filename)

    def default_pathname filename
      result =File.basename(filename).gsub( /\.war/i , "")
      result
    end
    path = default_pathname(filename) if path.nil?

    response = request("/manager/deploy?path=/#{path}",:put) do |req|
      File.open(filename){ |f| req.body = f.read }
    end

    puts response.body
  end

  def serverinfo
    request('/manager/serverinfo').body
  end

  def request(path,method=:get)
    Net::HTTP.start(@host,@port) do |http|
      case method
      when :get
        req = Net::HTTP::Get.new(path)
      when :put
        req = Net::HTTP::Put.new(path)
      else
        raise ArgumentError.new("invalid method #{method}")
      end

      req.basic_auth @manager, @password

      yield req if block_given?

      response = http.request(req)
      raise TomcatManager::Unauthorized if response.code == "401"
      
      return response
    end
  end

  

end
