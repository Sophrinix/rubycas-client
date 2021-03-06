module CASClient
  module Tickets
    module Storage

      # A Ticket Store that keeps it's ticket in database tables using ActiveRecord.
      #
      # Services Tickets are stored in an extra column add to the ActiveRecord sessions table.
      # Proxy Granting Tickets and their IOUs are stored in the cas_pgtious table.
      #
      # This ticket store takes the following config parameters
      # :pgtious_table_name - the name of the table 
      class ActiveRecordTicketStore < AbstractTicketStore

        def initialize(config={})
          config ||= {}
          if config[:pgtious_table_name]
            CasPgtiou.set_table_name = config[:pgtious_table_name]
          end
        end

        def store_service_session_lookup(st, controller)
          #get the session from the rack env using ActiveRecord::SessionStore::SESSION_RECORD_KEY = 'rack.session.record'

          st = st.ticket if st.kind_of? ServiceTicket
          session = controller.request.env[ActiveRecord::SessionStore::SESSION_RECORD_KEY]
          session.service_ticket = st
        end

        def get_session_for_service_ticket(st)
          st = st.ticket if st.kind_of? ServiceTicket
          session = ActiveRecord::SessionStore::Session.find_by_service_ticket(st)
          session_id = session ? session.session_id : nil
          [session_id, session]
        end

        def cleanup_service_session_lookup(st)
          #no cleanup needed for this ticket store
        end

        def save_pgt_iou(pgt_iou, pgt)
          pgtiou = CasPgtiou.create(:pgt_iou => pgt_iou, :pgt_id => pgt)
        end

        def retrieve_pgt(pgt_iou)
          raise CASException, "No pgt_iou specified. Cannot retrieve the pgt." unless pgt_iou

          pgtiou = CasPgtiou.find_by_pgt_iou(pgt_iou)
          pgt = pgtiou.pgt_id

          raise CASException, "Invalid pgt_iou specified. Perhaps this pgt has already been retrieved?" unless pgt

          pgtiou.destroy

          pgt

        end

      end
      puts "loaded active record ticket store!"
      ::ACTIVE_RECORD_TICKET_STORE = ActiveRecordTicketStore

      class CasPgtiou < ActiveRecord::Base
        #t.string :pgt_iou, :null => false
        #t.string :pgt_id, :null => false
        #t.timestamps
      end
    end
  end
end
