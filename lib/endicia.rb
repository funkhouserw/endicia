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
		      label_request << XmlNode.new('AccountID', @default_options[:AccountID]) if @default_options.has_key?(:AccountID) and @default_options[:AccountID].present?
          label_request << XmlNode.new('RequesterID', @default_options[:RequesterID]) if @default_options.has_key?(:RequesterID) and @default_options[:RequesterID].present?
          label_request << XmlNode.new('PassPhrase', @default_options[:PassPhrase]) if @default_options.has_key?(:PassPhrase) and @default_options[:PassPhrase].present?
          
		      label_request << XmlNode.new('FromName', @default_options[:FromName]) if @default_options.has_key?(:FromName) and @default_options[:FromName].present?
          label_request << XmlNode.new('FromCompany', @default_options[:FromCompany]) if @default_options.has_key?(:FromCompany) and @default_options[:FromCompany].present?
          label_request << XmlNode.new('ReturnAddress1', @default_options[:ReturnAddress1]) if @default_options.has_key?(:ReturnAddress1) and @default_options[:ReturnAddress1].present?
          label_request << XmlNode.new('FromCity', @default_options[:FromCity]) if @default_options.has_key?(:FromCity) and @default_options[:FromCity].present?
          label_request << XmlNode.new('FromState', @default_options[:FromState]) if @default_options.has_key?(:FromState) and @default_options[:FromState].present?
          label_request << XmlNode.new('FromPostalCode', @default_options[:FromPostalCode]) if @default_options.has_key?(:FromPostalCode) and @default_options[:FromPostalCode].present?
		  
          label_request << XmlNode.new('ToPostalCode', @default_options[:ToPostalCode]) if @default_options.has_key?(:ToPostalCode) and @default_options[:ToPostalCode].present?
          label_request << XmlNode.new('ToName', @default_options[:ToName]) if @default_options.has_key?(:ToName) and @default_options[:ToName].present?
          label_request << XmlNode.new('ToCompany', @default_options[:ToCompany]) if @default_options.has_key?(:ToCompany) and @default_options[:ToCompany].present?
          label_request << XmlNode.new('ToAddress1', @default_options[:ToAddress1]) if @default_options.has_key?(:ToAddress1) and @default_options[:ToAddress1].present?
		      label_request << XmlNode.new('ToAddress2', @default_options[:ToAddress2]) if @default_options.has_key?(:ToAddress2) and @default_options[:ToAddress2].present?
          label_request << XmlNode.new('ToCity', @default_options[:ToCity]) if @default_options.has_key?(:ToCity) and @default_options[:ToCity].present?
          label_request << XmlNode.new('ToState', @default_options[:ToState]) if @default_options.has_key?(:ToState) and @default_options[:ToState].present?
          label_request << XmlNode.new('PartnerTransactionID',@default_options[:PartnerTransactionID]) if @default_options.has_key?(:PartnerTransactionID) and @default_options[:PartnerTransactionID].present?
          label_request << XmlNode.new('PartnerCustomerID', @default_options[:PartnerCustomerID]) if @default_options.has_key?(:PartnerCustomerID) and @default_options[:PartnerCustomerID].present?
          label_request << XmlNode.new('MailClass', @default_options[:MailClass]) if @default_options.has_key?(:MailClass) and @default_options[:MailClass].present?
          label_request << XmlNode.new('WeightOz', @default_options[:WeightOz]) if @default_options.has_key?(:WeightOz) and @default_options[:WeightOz].present?
		  label_request << XmlNode.new('CostCenter', @default_options[:CostCenter]) if @default_options.has_key?(:CostCenter) and @default_options[:CostCenter].present?
        end
		Rails.logger.debug request.to_s
		body = "labelRequestXML=" + request.to_s
		Rails.logger.debug body
		result = self.class.post("https://LabelServer.Endicia.com/LabelService/EwsLabelService.asmx/GetPostageLabelXML", :body => body)
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
