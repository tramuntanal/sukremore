module Sukremore
  module Modules
    class Email < Base
      MODULE_NAME= 'EmailAddresses'
      # GET  --------------------
      # Returns the ID for the given email if it exists, false otherwise.
      def email_id? email
        raise "email can't be nil" if email == nil
        sugar_resp = @client.get_entry_list(MODULE_NAME, {
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
          sugar_resp['entry_list'][0]['id']
        else
          false
        end
      end

      # SET
      # insert email.
      # Returns the email id on success, otherwise returns nil.
      def insert_email email
        raise "really? add new a new empty account?" if email.nil? or email.empty?

        email_params = {
          email_address: email,
          email_address_caps: email.upcase,
          invalid_email: false,
          opt_out: false,
          created_at: Time.now,
          updated: Time.now
        }

        @client.set_entry Email::MODULE_NAME, email_params
      end

    end
  end
end
