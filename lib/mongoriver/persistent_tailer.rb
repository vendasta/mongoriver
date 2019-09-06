module Mongoriver
  # A variant of AbstractPersistentTailer that automatically persists
  # the "last timestamp processes" state into the database we are
  # tailing.
  class PersistentTailer < AbstractPersistentTailer
    def initialize(upstream, type, service, opts={})
      if type == :slave
        raise "You can't use PersistentTailer against only a slave. How am I supposed to write state?"
      end
      super(upstream, type, opts)

      db         = opts[:db] || "_mongoriver"
      collection = opts[:collection] || 'oplog-tailers'
      @service = service
      @state_collection = @upstream_conn.use(db)[collection]
    end

    def read_state
      row = @state_collection.find(:service => @service).first
      return nil unless row

      case row['v']
      when nil
        log.warn("Old style timestamp found in database. Converting!")
        ts = Time.at(row['timestamp'].seconds)
        return {
          'position' => most_recent_position(ts),
          'time' => ts
        }
      when 1
        return row['state']
      end
    end

    def write_state(state)
      @state_collection.update_one({:service => @service},
        {:service => @service, :state => state, :v => 1}, :upsert => true)
    end
  end
end
