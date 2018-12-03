# Eve #

This is a research project around the topic of Event Sourcing. It should be considered Alpha.

## How to use ##

Create a Perl package for your entities. This package is your namespace. You register your entities into that namespace. It also serves as your entrypoint to obtain instances that you use to do your actions.

See [MyStorage.pm](t/lib/MyStorage.pm), and the tests, in particular [10_registry.t](t/10_registry.t) and [20_ops.t](t/20_ops.t). These two will give you a simple example on how all the pieces fit together. You can also see the next section, _Concepts_, on details about all the classes fit together.

You register your entity types with `YourNameSpace->register()` and you get a repository object with `YourNameSpace->connect()`. The parameters to this are Driver specific. For DBI-based drivers the parameters are the basic `DBI->connect()` parameters.

With this repository object you can then call specific methods:

* `deploy()`: deploys all the tables needed for this to work. This applies mostly to DBI-based Drivers. Other Drivers might have different deployment strategies.;
* `create()`: create a new entity;
* `update()`: update an existing entity. You'll need to provide a type and ID, plus the new blob. You can optionally provide a previous version ID that can be used for a optimistic locking mechanism;
* `fetch()`: obtains a entity and optionally, metadata associated with it;
* `events()`: list all events that were used to reach the last version of the entity.


## Concepts ##

To better understand how everthing together, lets walk through some concepts.

This system provides a storage system for entities. Each entity has a type. You register types with the system, and afterwards you can store entities of that type. Each type can also maintain a set of extra tables for your own purposes. Maybe you need extra search criteria, or you need extra uniqueness restrictions, you can use an extra table or tables to implement them.

Each type allows you to register operations with each type. There are 6 operations available at the moment:

* `deploy`: a deploy operation is called when you call `deploy()`. This allows you to deploy your extra tables;
* `id`: based on the information provided to a `create()` method, this operation must return the ID for the entity. You can use a random secure ID, like a UUID or a ULID, or something specific to your needs. You can even use a table with an auto-increment ID just for this;
* `before`: a operation called before the main operations, `create` or `update`. This is usually used to maintain the extra tables in sync with the entity blob;
* `after`: same as before, but called after the main operation is done;
* `marshal` and `unmarshal`: converts the blob and meta structures to and from Perl structures to a DB-compatible format. These are the only operations with default implementation which uses JSON.

Each instance of an entity has a type, an ID, and a version identifier. The version identifiers are a sequence of natural numbers. They start at 1 and grow from there. The ID is whatever you want. You generate them using the `id` operation.

Each entity has a blob that you pass as a parameter on all `create()` and `update()` calls. The blob replaces the previous version. The events keep track of all the blobs from the past.

## Main classes ##

The system requires a namespace class. This class uses the [`Eve`](lib/Eve.pm) class as parent, and inherits the `connect()` method and the type registry methods.

When you use the `connect()` method, you get a repository instance, which is a based on the [`Eve::Driver`](lib/Eve/Driver.pm) class. This class implements the main repository methods: `create()`, `update()`, `fetch()` and `events()`.

The rest of the code is DB-specific Drivers. For now there is a [`Eve::Driver::SQLite`](lib/Eve/Driver/SQLite.pm) driver for SQLite DB. There is also a [`Eve::Driver::DBI`](lib/Eve/Driver/DBI.pm) class but this is an base class with shared code for all DBI-based drivers. In particular it includes a couple of SQL helpers.

