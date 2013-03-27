module Pione
  module Tuple
    # TicketTuple is a tuple representation of ticket.
    class TicketTuple < BasicTuple
      define_format [:ticket, :domain, :ticket_name]
    end
  end
end
