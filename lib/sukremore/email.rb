module Sukremore
  module Email
    MODULE_NAME= 'EmailAddresses'
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

      sugar_resp= set_entry Email::MODULE_NAME, email_params
      return sugar_resp["id"] || nil
    end

  end
end
