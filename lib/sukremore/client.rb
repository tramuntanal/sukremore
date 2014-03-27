require 'net/http'
require 'net/https'
require 'json'
# 
# 
module Sukremore
  class Client
    def initialize url
      @url= url
    end

    def user_auth
      sugar_resp = sugar_do_rest_call(
        @url, 
        'login', 
        :user_auth => {:user_name => config['crm']['username'], :password => Digest::MD5.hexdigest(config['crm']['password']), :version => config['crm']['api_version']}
      )
      @session_id = sugar_resp['id']
      raise "Error to login in SugarCRM, session_id is nil" if session_id.blank?
    end

    #
    # Do a rest call to a SugarCRM Account by the given query
    #
    def sugar_get_account_by_query sql_cond= nil
      raise "session_id[#{@session_id}]/url[#{@url}] can't be nil" if @session_id == nil || @url == nil
  
      sugar_resp = sugar_do_rest_call(
        url, 
        'get_entry_list',
        { :session => @session_id, 
          :module_name => "Accounts", 
          :query => sql_cond, # the SQL WHERE clause without the word “where”.
          :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
          :offset => '0', # the record offset from which to start.
          :select_fields => ['id', 'nif_code_c', 'name', 'billing_address_street', 'phone_office_label', 'billing_address_city', 'billing_address_state', 'billing_address_postalcode', 'billing_address_country', 'website', 'email_adresse_c'],
          :max_results => '10',
          #:link_name_to_fields_array => [{:name => 'id'}, {:value => ['id', 'name']}],
          :deleted => 0, # exclude deleted records
          :favorites => false # if only records marked as favorites should be returned.
        }
      )
  
      return sugar_resp
    end

    private
    #
    # Do a POST to SugarCRM
    #
    def sugar_do_rest_call(url, method, params = {})
      uri = URI(url)
      http = Net::HTTP.new uri.host, uri.port
      http.open_timeout = 30
      # Uncoment this two lines for use SSL
      # http.use_ssl = true
      # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
      post_data = {
        :method => method,
        :input_type => 'JSON',
        :response_type => 'JSON',
        :rest_data => params.to_json,
      }
      http_resp = Net::HTTP.post_form(uri, post_data)
      JSON.parse(http_resp.body)
    end
  end
end