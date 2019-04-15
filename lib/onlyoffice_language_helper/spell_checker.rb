# encoding=utf-8
require 'hunspell-ffi'
require 'active_support/configurable'
require 'httparty'
require 'json'
require 'cgi'
require 'whatlanguage'
require_relative 'spell_checker/dictionaries_threads'

# Spellchecker stuff
module OnlyofficeLanguageHelper
  # USAGE:
  # SpellChecker.configure do |config|
  #  config.expected_language = 'lv_LV'
  # end
  #
  # SpellChecker.check_in_all_dictionaries("viens no veidiem, iespieddarbiem: nav periodisks izdevums")
  module SpellChecker
    include HTTParty
    attr_reader :config

    def self.configure
      OnlyofficeLoggerHelper.log('Begin configuring SpellChecker')
      config
      yield(@config) if block_given?
      check_language
      @dictionary = Hunspell.new(path_to_dic_aff(:aff), path_to_dic_aff(:dic))
      OnlyofficeLoggerHelper.log('Configuring complete!')
    end

    def self.check_in_all_dictionaries(string)
      check_configuration
      @dictionaries ||= DictionariesThreads.new
      split_text_by_words(string).map { |word| parse_spellcheck_result(word, @dictionaries.check_word(word)) }
    end

    def self.path_to_dic_aff(extension, language = config.expected_language)
      config.dictionaries_path + "/dictionaries/#{language}/#{language}.#{extension}"
    end

    # Spellchecker config
    class Config
      include ActiveSupport::Configurable

      config_accessor :expected_language
      config_accessor :dictionaries_path

      def initialize
        default_configuration
      end

      def default_configuration
        self.expected_language = 'en_US'
        self.dictionaries_path = File.dirname(__FILE__)
      end
    end

    private_class_method

    def self.split_text_by_words(string)
      string.to_s.scan(/\b[[:word:]['-]]+\b/u).uniq
    end

    def self.parse_spellcheck_result(word, spellcheck_result)
      unless spellcheck_result[config.expected_language]
        warn "Word '#{word}' was not found in '#{config.expected_language}' dictionary!"
        spellcheck_result['suggestions'] = @dictionary.suggest(word)
      end
      { word => spellcheck_result }
    end

    def self.config
      @config ||= Config.new
    end

    def self.check_configuration
      raise 'Call SpellChecker.configure method before using it!' unless @dictionary
    end

    def self.check_language
      raise 'Incorrect language' unless File.exist?(path_to_dic_aff(:dic)) || File.exist?(path_to_dic_aff(:aff))
    end
  end
end
