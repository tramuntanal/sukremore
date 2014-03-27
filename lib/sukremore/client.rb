require 'net/http'
require 'net/https'
require 'json'
# 
# 
module Sukremore
  class Client
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
      puts "Rs:::#{sugar_resp}"
      @session_id = sugar_resp['id']
      raise "Error performing login to SugarCRM, returned session_id is nil" if @session_id.blank?
    end

    #
    # Do a rest call to a SugarCRM Account by the given query
    #
    def sugar_get_account_by_query sql_cond= nil
      raise "session_id[#{@session_id}]/url[#{@url}] can't be nil" if @session_id == nil || @url == nil
  
      sugar_resp = sugar_do_rest_call(
        @url,
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

    def insert_or_update_lead lead
      email_id= email_id?(lead[:email])
      unless email_id
        # insert
        email_id= insert_email(lead[:email])
        lead_id= set_lead(lead)
        set_email_lead_relationship email_id, lead_id
      else
        # update
        lead= get_lead_by_email email_id
        lead[:email_id] = email_id
        set_lead(lead)
      end
    end

    # GET  --------------------
    # Returns the ID for the given email if it exists, false otherwise.
    def email_id? email
      raise "email can't be nil" if email == nil
      sugar_resp = sugar_do_rest_call(
        @url,
        'get_entry_list',
        { :session => @session_id, 
          :module_name => "EmailAddresses", 
          :query => 'email_address=\''+ email +'\'',#"email_address IN ('#{email}')", # the SQL WHERE clause without the word “where”.
          :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
          :offset => '0', # the record offset from which to start.
          :select_fields => ['email_address'],
          :max_results => '1',
          #:link_name_to_fields_array => [{:name => 'id'}, {:value => ['id', 'name']}],
          :deleted => 0, # exclude deleted records
          :favorites => false # if only records marked as favorites should be returned.
        }
      )
      if sugar_resp['entry_list'].any?
        sugar_resp['entry_list'][0]['email_id']
      else
        false
      end
    end

    # SET
    # insert email.
    # Returns the email id on success, otherwise returns nil.
    def insert_email email
      raise "really? add new a new empty account?" if email.nil? or email.empty?

      email_params = []
      email_params << {:name => "email_address", :value => email}
      email_params << {:name => "email_address_caps", :value => email.upcase}
      email_params << {:name => "invalid_email", :value => false}
      email_params << {:name => "opt_out", :value => false}
      email_params << {:name => "created_at", :value => Time.now}
      email_params << {:name => "updated", :value => Time.now}

      sugar_resp = sugar_do_rest_call(
        @url,
        'set_entry',
        {
          :session => @session_id,
          :module_name => "EmailAddresses",
          :name_value_list => email_params
        }
      )
      puts "RS:::::::::::::::#{sugar_resp}"
      return sugar_resp["id"] || nil
    end

    # insert lead
    # Returns the id of the lead on success, otherwise returns nil.
    def set_lead lead=[]
      raise "really? add new a new empty account?" if lead.length == 0   

      web_user_id= retrieve_web_user()

      email_params = []
      email_params << {:name => "id", :value => lead[:lead_id]} if lead[:lead_id].present?
      email_params << {:name => "date_entered", :value => Time.now} if lead[:lead_id].blank?
      email_params << {:name => "date_modified", :value => Time.now}
      email_params << {:name => "modified_user_id", :value => web_user_id} if lead[:lead_id].blank?
      email_params << {:name => "created_by", :value => web_user_id}  if lead[:lead_id].blank?
      if lead[:lead_desc].blank?
        email_params << {:name => "description", :value => "Lead generated from #{@endpoint_name}-> [(#{Time.now})- #{lead[:text]}]"}
      else
        email_params << {:name => "description", :value => "#{lead[:lead_desc]} [(#{Time.now})- #{lead[:text]}]"}
      end
      email_params << {:name => "deleted", :value => false} if lead[:lead_id].blank?
      email_params << {:name => "assigned_user_id", :value => nil} if lead[:lead_id].blank?
      email_params << {:name => "last_name", :value => lead[:name]} if lead[:lead_id].blank?
      email_params << {:name => "lead_source", :value => "Web Site"} if lead[:lead_id].blank?
      email_params << {:name => "status", :value => "New"} if lead[:lead_id].blank?

      sugar_resp = sugar_do_rest_call(
        @url,
        'set_entry',
        {
          :session => @session_id,
          :module_name => "Leads",
          :name_value_list => email_params
        }
      )
      return sugar_resp["id"] || nil
    end

    # GET
    # Get the user named user_web
    # Returns the given user or nil if not found.
    def retrieve_web_user
      sugar_resp = sugar_do_rest_call(
        @url, 
        'get_entry_list',
        { :session => @session_id, 
          :module_name => "Users", 
          :query => 'user_name=\'user_web\'',#"email_address IN ('#{email}')", # the SQL WHERE clause without the word “where”.
          :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
          :offset => '0', # the record offset from which to start.
          :select_fields => ['email_address'],
          :max_results => '1',
          #:link_name_to_fields_array => [{:name => 'id'}, {:value => ['id', 'name']}],
          :deleted => 0, # exclude deleted records
          :favorites => false # if only records marked as favorites should be returned.
        }
      )
      return nil if sugar_resp["entry_list"].length == 0
      return sugar_resp["entry_list"][0]["id"]
    end

    # SET
    # Insert relation between lead and email
    def set_email_lead_relationship email_id, lead_id
      sugar_resp = sugar_do_rest_call(
        @url,
        'set_relationship',
        {
          :session => @session_id,
          :module_name => "Leads",
          :module_id => lead_id,
          :link_field_name => 'email_addresses',
          :related_ids => [email_id],
        }
      )
      return sugar_resp["id"] || nil
    end

    # GET lead id and desc searching by email
    def get_lead_by_email email_id
      query = %Q{leads.id in
      (select email_addr_bean_rel.bean_id 
        from email_addr_bean_rel 
        where email_addr_bean_rel.bean_module = 'Leads'
        and email_addr_bean_rel.email_address_id = '#{email_id}'
        )
      }
      sugar_resp = sugar_do_rest_call(
        @url,
        'get_entry_list',
        { :session => @session_id,
          :module_name => "Leads", 
          :query => query,
          :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
          :offset => '0', # the record offset from which to start.
          :select_fields => ['id', 'description'],
          :max_results => '1',
          #:link_name_to_fields_array => [{:name => 'id'}, {:value => ['id', 'name']}],
          :deleted => 0, # exclude deleted records
          :favorites => false # if only records marked as favorites should be returned.
        }
      )
      return {:lead_id => nil, :lead_desc => ""} if sugar_resp["entry_list"].length == 0
      {:lead_id => sugar_resp["entry_list"][0]["id"], :lead_desc => sugar_resp["entry_list"][0]["name_value_list"]["description"]["value"]}
    end

    #--------------------------------------------------------------------------
    private
    #--------------------------------------------------------------------------

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