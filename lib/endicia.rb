require 'rubygems'
require 'httparty'
require 'nokogiri'

module Endicia
 
  class API
    include HTTParty
	format :xml
	
	attr_accessor :default_options
	  # We need the following to make requests
	  # RequesterID (string): Requester ID (also called Partner ID) uniquely identifies the system making the request. Endicia assigns this ID. The Test Server does not authenticate the RequesterID. Any text value of 1 to 50 characters is valid.
	  # AccountID (6 digits): Account ID for the Endicia postage account. The Test Server does not authenticate the AccountID. Any 6-digit value is valid.
	  # PassPhrase (string): Pass Phrase for the Endicia postage account. The Test Server does not authenticate the PassPhrase. Any text value of 1 to 64 characters is valid.

	  # if we're in a Rails env, let's load the config file
	def initialize
		if defined? Rails.root
			rails_root = Rails.root.to_s 
		elsif defined? RAILS_ROOT
			rails_root = RAILS_ROOT 
		end
		@default_options = YAML.load_file(File.join(rails_root, 'config', 'endicia.yml'))[Rails.env].symbolize_keys if defined? rails_root and File.exist? "#{rails_root}/config/endicia.yml" 
		@default_options = Hash.new if default_options.nil?
    end
	# We probably want the following arguments
	# MailClass, WeightOz, MailpieceShape, Machinable, FromPostalCode

	
	# example XML
	  def get_label(opts={})
		Rails.logger.debug @default_options.inspect
	    @default_options.merge!(opts)
		Rails.logger.debug @default_options.inspect
		request = XmlNode.new('LabelRequest', :Test => @default_options[:Test], :LabelSize => @default_options[:LabelSize], :ImageFormat => @default_options[:ImageFormat], :LabelType => @default_options[:LabelType], :ImageRotation => @default_options[:ImageRotation]) do |label_request|
          #label_request << XmlNode.new('Test', @default_options[:Test])
		  label_request << XmlNode.new('AccountID', @default_options[:AccountID]) if @default_options.has_key?(:AccountID)
          label_request << XmlNode.new('RequesterID', @default_options[:RequesterID]) if @default_options.has_key?(:RequesterID)
          label_request << XmlNode.new('PassPhrase', @default_options[:PassPhrase]) if @default_options.has_key?(:PassPhrase)
          
		  label_request << XmlNode.new('FromName', @default_options[:FromName]) if @default_options.has_key?(:FromName)
          label_request << XmlNode.new('FromCompany', @default_options[:FromCompany]) if @default_options.has_key?(:FromCompany)
          label_request << XmlNode.new('ReturnAddress1', @default_options[:ReturnAddress1]) if @default_options.has_key?(:ReturnAddress1)
          label_request << XmlNode.new('FromCity', @default_options[:FromCity]) if @default_options.has_key?(:FromCity)
          label_request << XmlNode.new('FromState', @default_options[:FromState]) if @default_options.has_key?(:FromState)
          label_request << XmlNode.new('FromPostalCode', @default_options[:FromPostalCode]) if @default_options.has_key?(:FromPostalCode)
		  
          label_request << XmlNode.new('ToPostalCode', @default_options[:ToPostalCode]) if @default_options.has_key?(:ToPostalCode)
          label_request << XmlNode.new('ToName', @default_options[:ToName]) if @default_options.has_key?(:ToName)
          label_request << XmlNode.new('ToCompany', @default_options[:ToCompany]) if @default_options.has_key?(:ToCompany)
          label_request << XmlNode.new('ToAddress1', @default_options[:ToAddress1]) if @default_options.has_key?(:ToAddress1)
		  label_request << XmlNode.new('ToAddress2', @default_options[:ToAddress1]) if @default_options.has_key?(:ToAddress2)
          label_request << XmlNode.new('ToCity', @default_options[:ToCity]) if @default_options.has_key?(:ToCity)
          label_request << XmlNode.new('ToState', @default_options[:ToState]) if @default_options.has_key?(:ToState)
          label_request << XmlNode.new('PartnerTransactionID',@default_options[:PartnerTransactionID]) if @default_options.has_key?(:PartnerTransactionID)
          label_request << XmlNode.new('PartnerCustomerID', @default_options[:PartnerCustomerID]) if @default_options.has_key?(:PartnerCustomerID)
          label_request << XmlNode.new('MailClass', @default_options[:MailClass]) if @default_options.has_key?(:MailClass)
          label_request << XmlNode.new('WeightOz', @default_options[:WeightOz]) if @default_options.has_key?(:WeightOz)
        end
		Rails.logger.debug request.to_s
		body = "labelRequestXML=" + request.to_s
		Rails.logger.debug body
		result = self.class.post("https://www.envmgr.com/LabelService/EwsLabelService.asmx/GetPostageLabelXML", :body => body)
		return Endicia::Label.new(result["LabelRequestResponse"])
	  end
  end 
  
  class Label
    attr_accessor :image, 
                  :status, 
                  :tracking_number, 
                  :final_postage, 
                  :transaction_date_time, 
                  :transaction_id, 
                  :postmark_date, 
                  :postage_balance, 
                  :pic,
                  :error_message
    def initialize(data)
      data.each do |k, v|
        k = "image" if k == 'Base64LabelImage'
        send(:"#{k.tableize.singularize}=", v) if !k['xmlns']
      end
    end
  end
end
