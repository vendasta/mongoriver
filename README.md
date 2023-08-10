# Mongoriver

mongoriver is a library to monitor updates to your Mongo databases in
near-realtime. It provides a simple interface for you to take actions
when records are inserted, removed, or updated.


## How it works

MongoDB has an *oplog*, a log of all write operations. `mongoriver` monitors
updates to this oplog. See the [Mongo documentation for its oplog](http://docs.mongodb.org/manual/core/replica-set-oplog/) for more.

## How to use it

### Step 1: Create an outlet

You'll need to write a class subclassing
[Mongoriver::AbstractOutlet](https://github.com/Yesware/mongoriver/blob/master/lib/mongoriver/abstract_outlet.rb).

You can override any of these methods:

* `update_optime(timestamp)`
* `insert(db_name, collection_name, document)`
* `remove(db_name, collection_name, document)`
* `update(db_name, collection_name, selector, update)`
* `create_index(db_name, collection_name, index_key, options)`
* `drop_index(db_name, collection_name, index_name)`
* `create_collection(db_name, collection_name,  options)`
* `drop_collection(db_name, collection_name)`
* `rename_collection(db_name, old_collection_name, new_collection_name)`
* `drop_database(db_name)`


You should think of these methods like callbacks -- if you want to do something
every time a document is inserted into the Mongo database, override the
`insert` method. You don't need to override all the methods -- if you only want
to take action on insert and update, just override `insert` and `update`.

### Step 2: Create a stream and start the logger

Once you've written your class, you can start tailing the Mongo oplog! Here's
the code you'll need to use:

```ruby
mongo = Mongo::MongoClient.from_uri(mongo_uri)
tailer = Mongoriver::Tailer.new([mongo], :existing)
outlet = YourOutlet.new(your_params) # Your subclass of Mongoriver::AbstractOutlet here
stream = Mongoriver::Stream.new(tailer, outlet)
# install a shutdown handler so we can make sure to stop things cleanly
trap('TERM') do
  stream.stop
end
stream.run_forever(starting_timestamp)
tailer.save_state
```

`starting_timestamp` here is the time you want the tailer to start at. We use
this to resume interrupted tailers so that no information is lost.


## Version history

### 1.3.0

Ignore `applyOps` command instead of throwing error.

### 1.2.1

Allow the oplog cursor peek operation used by the tailer to be interrupted
by adding a `max_time_ms` option to the query (which has the side effect of
the wait for the next oplog item interruptible as well).  Also, handle the
error this returns and turn it into a `false` return to wrap up the stream.

### 1.2.0

Support `createIndexes` command (it's just another way of creating indexes),
recognize but drop `collMod` commands.

### 1.1.0

Allow both v1 and v2 indexes when handling index creation ops.

### 1.0.0

Fix persistent tailers read state approach.

### 0.7.0

Fix outlet method nomenclature to keep compatibility with pre-existing API.

### 0.6.0

Fork and move to Yesware. Correct Mongo 2.0 collection method naming.

### 0.5.0

Move from the Moped driver to the native Mongo 2.0 driver.

### 0.4.0

Add support for [tokumx](http://www.tokutek.com/products/tokumx-for-mongodb/). Backwards incompatible changes to persistent tailers to accommodate that. See [UPGRADING.md](UPGRADING.md).

