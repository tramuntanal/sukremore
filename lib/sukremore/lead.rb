module Sukremore
  class Lead
    MODULE_NAME= 'Leads'

    def initialize client
      @client= client
    end

    #
    # NOTE: To be used on Sugar versions from 6.5.
    # Sugar versions below can use set_lead directly.
    #
    def insert_or_update_lead lead
      email_id= email_id?(lead[:email1])
      unless email_id
        # insert
        email_id= insert_email(lead[:email1])
        lead_id= set_lead(lead)
        set_relationship Lead::MODULE_NAME, lead_id, 'email_addresses', [email_id]
      else
        # update
        lead= get_lead_by_email email_id
        lead[:email_id] = email_id
        set_lead(lead)
      end
    end

    # Inserts a new lead into the SugarCRM.
    # 
    # NOTE: To be used on Sugar versions around 6.0.
    # Sugar versions greater must use inser_or_update_lead.
    #
    # Accepted params (symbol keys) are:
    # - :lead_id <- may be null on create.
    # - :lead_desc
    # - :name
    # - :email1
    # 
    # Returns the id of the lead on success, otherwise returns nil.
    def set_lead lead={}
      raise "really? add new a new empty lead?" if lead.empty?

      if lead[:description].nil? or lead[:description].empty?
        lead[:description]= "Lead generated from #{@client.endpoint_name}-> [(#{Time.now})- #{lead[:text]}]"
      end
      if lead[:lead_source].nil? || lead[:lead_source].empty?
        lead[:lead_source]= @client.endpoint_name
      end
      if lead[:status].nil? || lead[:status].empty?
        lead[:lead_source]= 'New'
      end

      @client.set_entry Lead::MODULE_NAME, lead
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
      sugar_resp = @client.get_entry_list(MODULE_NAME, {
        :query => query,
        :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
        :offset => '0', # the record offset from which to start.
        :select_fields => ['id', 'description'],
        :max_results => '1',
        :deleted => 0, # exclude deleted records
        :favorites => false # if only records marked as favorites should be returned.
      })
      return {:lead_id => nil, :lead_desc => ""} if sugar_resp["entry_list"].length == 0
      {:lead_id => sugar_resp["entry_list"][0]["id"], :lead_desc => sugar_resp["entry_list"][0]["name_value_list"]["description"]["value"]}
    end

  end
end
