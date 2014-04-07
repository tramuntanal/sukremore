require 'net/http'
require 'net/https'
require 'json'
require 'sukremore/modules/base'
require 'sukremore/modules/account'
require 'sukremore/modules/email'
require 'sukremore/modules/lead'

# 
# To use the Sukremore::Client the first thing to do is call user_auth so that
# the client authenticates with SugarCRM. Once authenticated, the rest of the calls
# may be performed without authenticating again.
# 
# For more documentation on the SugarCRM Rest API check:
# http://xxx-crm.coditramuntana.com/service/v2/rest.php
#
module Sukremore
  class Client
    include Sukremore
    attr_reader :endpoint_name

    def initialize url, config
      @url= url
      @config= config
      @endpoint_name= @config['endpoint_name'] || 'Web'
    end

    # Authenticates with the given SugarCRM
    # Returns true if succeeded, false otherwise.
    def user_auth
      sugar_resp = sugar_do_rest_call(
        @url, 
        'login', 
        :user_auth => {:user_name => @config['username'], :password => Digest::MD5.hexdigest(@config['password']), :version => @config['api_version']}
      )
      @session_id = sugar_resp['id']
      @logged_user= find_user_by_name @config['username']
      raise "Error performing login to SugarCRM, returned session_id is nil" if @session_id.blank?
    end

    def from_leads
      Modules::Lead.new(self)
    end

    def from_accounts
      Modules::Account.new(self)
    end

    def from_emails
      Modules::Email.new(self)
    end

    # GET
    # Get the first user named with the name arg.
    # Returns nil if not found.
    #
    def find_user_by_name name
      users= find_users_by_name name
      users.first
    end

    # GET
    # Get the users named with the name arg.
    #
    def find_users_by_name name
      sugar_resp = sugar_do_rest_call(
        @url, 
        'get_entry_list',
        { :session => @session_id, 
          :module_name => "Users", 
          :query => "user_name='#{name}'",#"email_address IN ('#{email}')", # the SQL WHERE clause without the word “where”.
          :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
          :offset => '0', # the record offset from which to start.
          :select_fields => ['email_address'],
          :max_results => '1',
          #:link_name_to_fields_array => [{:name => 'id'}, {:value => ['id', 'name']}],
          :deleted => 0, # exclude deleted records
          :favorites => false # if only records marked as favorites should be returned.
        }
      )
      return sugar_resp["entry_list"]
    end

    # SET ENTRY
    # Creates or updates an entity
    def set_entry module_name, entry
      names_values = []
      names_values << {:name => "id", :value => entry[:id]} if entry[:id].present?
      names_values << {:name => "date_entered", :value => Time.now} if entry[:id].blank?
      names_values << {:name => "created_by", :value => @logged_user['id']}  if entry[:id].blank?
      names_values << {:name => "date_modified", :value => Time.now}
      names_values << {:name => "modified_user_id", :value => @logged_user['id']}
      entry.entries.each do |field, value|
        names_values << {:name => field, :value => value}
      end

      sugar_resp= sugar_do_rest_call(
        @url,
        'set_entry',
        {
          :session => @session_id,
          :module_name => module_name,
          :name_value_list => names_values
        }
      )
      sugar_resp['id']
    end

    def get_entry_list module_name, params={}
      sugar_rs= sugar_do_rest_call(
        @url,
        'get_entry_list',
        { :session => @session_id,
          :module_name => module_name, 
        }.merge(params)
      )
      sugar_rs
    end
    # SET
    # Insert relation between modules
    def set_relationship src_module_name, src_module_id, link_field_name, related_ids
      sugar_resp = sugar_do_rest_call(
        @url,
        'set_relationship',
        {
          :session => @session_id,
          :module_name => src_module_name,
          :module_id => src_module_id,
          :link_field_name => link_field_name,
          :related_ids => related_ids,
        }
      )
      sugar_resp["id"]
    end

    #
    # Converts a Sugar Entity into a simple Ruby hash.
    #
    def import_sugar_entity sugar_entity
      entity= {}
      sugar_entity['name_value_list'].values.each do |field|
        entity[field['name']]= field['value']
      end
      entity
    end
    #--------------------------------------------------------------------------
    private
    #--------------------------------------------------------------------------

    #
    # Do a POST to SugarCRM
    # 
    # NOTE: Order of +params+ IS important.
    # 
    #
    def sugar_do_rest_call(url, method, params = {})
      uri = URI(url)
      http = Net::HTTP.new uri.host, uri.port
      http.open_timeout = 30
      # Uncoment this two lines for use SSL
      # http.use_ssl = true
      # http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      json_params= params.to_json
      logger.debug "rest_call request method: #{method} params:#{json_params}"
      post_data = {
        :method => method,
        :input_type => 'JSON',
        :response_type => 'JSON',
        :rest_data => json_params,
      }
      http_resp = Net::HTTP.post_form(uri, post_data)
      logger.debug "rest_call response:::#{http_resp}=#{http_resp.body}"
      json_rs= JSON.parse(http_resp.body)
      if json_rs['number'] == 11
        # 11=> Invalid Session ID
        raise http_respt.body
      end
      json_rs
    end
  end
end