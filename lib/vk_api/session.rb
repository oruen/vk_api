# encoding: utf-8
# VK - это небольшая библиотечка на Ruby, позволяющая прозрачно обращаться к API ВКонтакте
# из Ruby.
#
# Author:: Nikolay Karev
# Copyright:: Copyright (c) 2011- Nikolay Karev
# License:: MIT License (http://www.opensource.org/licenses/mit-license.php)
#
# Библиотека VkApi имеет один класс - +::VK:Session+. После создания экземпляра сессии
# вы можете вызывать методы ВКонтакте как будто это методы сессии, например:
#   session = ::VkApi::Session.new app_id, api_secret
#   session.friends.get :uid => 12
# Такой вызов вернёт вам массив хэшей в виде:
#   # => [{'uid' => '123'}, {:uid => '321'}]

require 'net/http'
require 'uri'
require 'digest/md5'
require 'json'

module VkApi
  # Единственный класс библиотеки, работает как "соединение" с сервером ВКонтакте.
  # Постоянное соединение с сервером не устанавливается, поэтому необходимости в явном
  # отключении от сервера нет.
  # Экземпляр +Session+ может обрабатывать все методы, поддерживаемые API ВКонтакте
  # путём делегирования запросов.
  class Session
    VK_API_URL = 'http://api.vk.com/api.php'
    VK_OBJECTS = %w(friends photos wall audio video places secure language notes pages offers 
      questions messages newsfeed status polls subscriptions)
    attr_accessor :app_id, :api_secret

    # Конструктор. Получает следующие аргументы:
    # * app_id: ID приложения ВКонтакте.
    # * api_secret: Ключ приложения со страницы настроек
    def initialize app_id, api_secret, method_prefix = nil
      @app_id, @api_secret, @prefix = app_id, api_secret, method_prefix
    end


    # Выполняет вызов API ВКонтакте
    # * method: Имя метода ВКонтакте, например friends.get
    # * params: Хэш с именованными аргументами метода ВКонтакте
    # Возвращаемое значение: хэш с результатами вызова.
    # Генерируемые исключения: +ServerError+ если сервер ВКонтакте вернул ошибку.
    def call(method, params = {})
      params[:method] = @prefix ? "#{@prefix}.#{method}" : method
      params[:api_id] = app_id
      params[:format] = 'json'
      params[:sig] = sig(params.tap do |s|
        # stringify keys
        s.keys.each {|k| s[k.to_s] = s.delete k  }
      end)
      response = JSON.parse(Net::HTTP.post_form(URI.parse(VK_API_URL), params).body)      
      raise ServerError.new self, method, params, response['error'] if response['error']
      response['response']
    end
    
    # Генерирует подпись запроса
    # * params: параметры запроса
    def sig(params)
      Digest::MD5::hexdigest(
      params.keys.sort.map{|key| "#{key}=#{params[key]}"}.join + 
      api_secret) 
    end

    # Генерирует методы, необходимые для делегирования методов ВКонтакте, так friends, 
    # images
    def self.add_method method
      ::VkApi::Session.class_eval do 
        define_method method do 
          if (! var = instance_variable_get("@#{method}"))
            instance_variable_set("@#{method}", var = ::VkApi::Session.new(app_id, api_secret, method))
          end
          var
        end
      end
    end

    for method in VK_OBJECTS
      add_method method
    end
    
    # Перехват неизвестных методов для делегирования серверу ВКонтакте
    def method_missing(name, *args)
      call name, *args
    end

  end
  
  # Базовый класс ошибок
  class Error < ::StandardError; end
  
  # Ошибка на серверной стороне
  class ServerError < Error
    attr_accessor :session, :method, :params, :error
    def initialize(session, method, params, error)
      super "Server side error calling VK method: #{error}"
      @session, @method, @params, @error = session, method, params, error
    end
  end
  
end
