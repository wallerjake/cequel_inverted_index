Cequel Inverted Index
=====================

A rails generator to create a Cequel inverted index for Cassandra databases.

##Installation

Add this line to the :development section of your application's Gemfile:

`gem 'cequel_inverted_index' `

And then execute:

`$ bundle install`


##Usage:
  `rails generate cequel_inverted_index MODEL COLUMN [options]`

####Runtime options:
```
  -f, [--force]                    # Overwrite files that already exist
  -p, [--pretend], [--no-pretend]  # Run but do not make any changes
  -q, [--quiet], [--no-quiet]      # Suppress status output
  -s, [--skip], [--no-skip]        # Skip files that already exist
```
Description:
    Creates the support files needed to provide an inverted index for
    cassandra databases using the Cequel gem.

Example:

    `rails generate cequel_inverted_index MyAwesomeModel column_to_search`


This will create:

* `app\models\#{model}_#{column}_index.rb` *A new Cequel model that implements the inverted index*
* `app\models\concerns\inverted_index.rb` *A mixin for the above index model*
* `app\models\concerns\#{column}_search.rb` *A mixin for the primary model to extend it's functionality*

This will modify:

* your primary model to include the above concern.

The following methods will be available to your primary model class:

* `find_all_by_#{column}(value)` *Returns all records with given value in indexed column*
* `count_with_#{column}(value)` *Returns number of records with given value in indexed column*
* `any_with_#{column}?(value)` *Returns true if any records have given value in the indexed column*

Additionally, callbacks are registered on the primary model to keep the index table in sync with the primary table.

##Notes:
You will need to migrate your database after running the generator:

`rake cequel:migrate`

If you already have records in your database, your new index will not know about them.  You will need to re-index.  You can do that by executing a rake task that will be created for you:

`rake cequel:reindex_#{model}_#{column}_index`

##Why use an inverted index?

There are many articles about the need for an inverted index.  [Here's one I found useful.](http://www.wentnet.com/blog/?p=77)

Cassandra's primary index is distributed and synchronized across all the nodes in the cluster.  So any node knows where to find a record with a given primary key.  Consider this example model:

```ruby
class Business
  include Cequel::Record

  key :id, :uuid, auto: true
  column :name, :text
  column :city, :text, :index => true
end
```

To find a particular record using the primary key is straightforward: `Business.where(id: '12da217c-c808-11e4-bde6-69e8c13b2025')`

But what if you want to search by some other column?  In SQL, you can just use a `where` clause.  But you can't do that with Cassandra on a column that's not indexed.  Oftentimes, the solution is to add a secondary index, as was done with the column `city` in the example above.  Then you can say:

`Business.where(city: "Chicago")`

But you can't say `Business.where(name: "Spacely's Sprockets")` **because it's not indexed**.  So why not just add a secondary index like we did for `city`?  Because the `name` column will probably exhibit *high cardinality*.  Unlike primary indexes, Cassandra secondary indexes are not distributed and synchronized across all the nodes in the cluster.  That means that every node has to be queried.  We would expect a search like `Business.where(city: "Chicago")` to be expensive, as we expect a lot of results, and we expect every node to have data that we need.  Since Cassandra will have to go to every node regardless, the indexing does not cost us anything extra.  The `city` column has *low cardinality*: there are far fewer possible values than there are records in the database.  Contrast that with the *high cardinality* case of `name`, where we expect a small number of results - likely only one.  If Cassandra queried all the nodes, most would reply with 'Go Fish'.  That wastes a lot of bandwidth.  The usual solution is an **Inverted Index**.

We simply create another table where the primary key is the column we want to search on, and the value is the id (or set of ids) into the primary table:

```ruby
class BusinessNameIndex
  include Cequel::Record
  key :name, :text
  set :busniness_ids,  :uuid
end
```

We can now say:

`ids = BusinessNameIndex.where(name: "Spacely's Sprockets")`

and get back an array of IDs.  We then use those IDs to get your Business Records:

`Business.where(id: ids)`

That's two queries, but *both use the efficient primary key*, avoiding lots of 'Go Fish' activity.  Of course this index table needs to be updated in parallel to the primary table.  The generator inserts callbacks into your primary model to handle that.  It also generates the index model, and provides the methods that chain the two queries together into a single method:

`Business.find_all_by_name("Spacely's Sprockets")`

##Limitations:

Currently, the primary key column in the primary database is expected to be: `key :id, :uuid`, and the column type for the indexed column must be `text`.  If they are different, you will need to edit the generated files to reflect that.

