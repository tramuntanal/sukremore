module Sukremore
  module Lead
    MODULE_NAME= 'Leads'
    #
    # NOTE: To be used on Sugar versions from 6.5.
    # Sugar versions below can use set_lead directly.
    #
    def insert_or_update_lead lead
      email_id= email_id?(lead[:email])
      unless email_id
        # insert
        email_id= insert_email(lead[:email])
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
    # Sugar versions greater must use inser_od_update_lead.
    #
    # Accepted params (symbol keys) are:
    # - :lead_id <- may be null on create.
    # - :lead_desc
    # - :name
    # - :email
    # 
    # Returns the id of the lead on success, otherwise returns nil.
    def set_lead lead={}
      raise "really? add new a new empty lead?" if lead.empty?

      names_values = []
      names_values << {:name => "id", :value => lead[:lead_id]} if lead[:lead_id].present?
      names_values << {:name => "date_entered", :value => Time.now} if lead[:lead_id].blank?
      names_values << {:name => "created_by", :value => @logged_user['id']}  if lead[:lead_id].blank?
      names_values << {:name => "date_modified", :value => Time.now}
      names_values << {:name => "modified_user_id", :value => @logged_user['id']}
      if lead[:lead_desc].blank?
        names_values << {:name => "description", :value => "Lead generated from #{@endpoint_name}-> [(#{Time.now})- #{lead[:text]}]"}
      elsif !(lead[:lead_desc].nil? or lead[:lead_desc].empty?)
        names_values << {:name => "description", :value => "#{lead[:lead_desc]} [(#{Time.now})- #{lead[:text]}]"}
      end
      names_values << {:name => "email1", :value => lead[:email]}
      names_values << {:name => "deleted", :value => false} if lead[:lead_id].blank?
      #      names_values << {:name => "assigned_user_id", :value => nil}
      names_values << {:name => "last_name", :value => lead[:name]}
      names_values << {:name => "lead_source", :value => "Web Site"} if lead[:lead_id].blank?
      names_values << {:name => "status", :value => "New"} if lead[:lead_id].blank?

      sugar_resp = set_entry Lead::MODULE_NAME, names_values
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
          :module_name => Lead::MODULE_NAME, 
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

  end
end
