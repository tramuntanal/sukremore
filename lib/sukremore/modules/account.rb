#
# Account Module fields
# ---------------
# assigned_user_name
# modified_by_name
# created_by_name
# id
# name
# date_entered
# date_modified
# modified_user_id
# created_by
# description
# deleted
# assigned_user_id
# account_type
# industry
# annual_revenue
# phone_fax
# billing_address_street
# billing_address_city
# billing_address_state
# billing_address_postalcode
# billing_address_country
# rating
# phone_office
# phone_alternate
# website
# ownership
# employees
# ticker_symbol
# shipping_address_street
# shipping_address_city
# shipping_address_state
# shipping_address_postalcode
# shipping_address_country
# email1
# parent_id
# sic_code
# parent_name
# campaign_id
# campaign_name
# cifra_negocio_c
# interes_en_prod_c
# currency_id
#
module Sukremore
  module Modules
    class Account < Base
      MODULE_NAME= 'Accounts'
      #
      # Do a rest call to a SugarCRM Account by the given query
      #
      def sugar_get_account_by_query sql_cond= nil
        raise "session_id[#{@session_id}]/url[#{@url}] can't be nil" if @session_id == nil || @url == nil

        sugar_resp = @client.get_entry_list(MODULE_NAME, {
          :query => sql_cond, # the SQL WHERE clause without the word “where”.
          :order_by => '', # the SQL ORDER BY clause without the phrase “order by”.
          :offset => '0', # the record offset from which to start.
          :select_fields => ['id', 'nif_code_c', 'name', 'billing_address_street', 'phone_office_label', 'billing_address_city', 'billing_address_state', 'billing_address_postalcode', 'billing_address_country', 'website', 'email_adresse_c'],
          :max_results => '10',
          #:link_name_to_fields_array => [{:name => 'id'}, {:value => ['id', 'name']}],
          :deleted => 0, # exclude deleted records
          :favorites => false # if only records marked as favorites should be returned.
        })

        return sugar_resp
      end

      #
      # Opts:
      # - +select_fields+ defaults to all.
      #
      def find_all_accounts opts={}
        pending_pages= true
        accounts= []
        offset= 0
        sugar_resp= nil
        while pending_pages
          offset= sugar_resp['next_offset'] unless sugar_resp.nil?
          opts[:offset]= offset
          sugar_resp= query_accounts(opts)
          pending_pages= (sugar_resp['result_count'] > 0) && (sugar_resp['result_count'] != sugar_resp['next_offset'])
          sugar_resp['entry_list'].each do |sa|
            accounts << import_sugar_entity(sa)
          end
        end
        accounts
      end

      def query_accounts opts={}
        # Order of parameters IS important
        params= {}
        params[:query]= opts[:query] unless opts[:query].nil?
        ## the record offset from which to start.
        params[:offset]= opts[:offset].nil? ? 0 : opts[:offset]
        # exclude deleted records
        params[:deleted]= opts[:deleted].nil? ? 0 : opts[:deleted]
        params[:select_fields]= opts[:select_fields] unless opts[:select_fields].nil?
        params[:offset]= opts[:offset] unless opts[:offset].nil?
        sugar_resp = @client.get_entry_list(MODULE_NAME)

        return sugar_resp
      end

      #-----------------------------------------------------------
      private
      #-----------------------------------------------------------

    end
  end
end
