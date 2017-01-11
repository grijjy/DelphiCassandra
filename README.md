# Working with big data databases in Delphi – Cassandra, Couchbase and MongoDB (Part 1 of 3)
 
This is the first part of a three-part series on working with big data databases directly from Delphi. In the first part we focus on a basic class framework for working with Cassandra along with an example application.![](http://i.imgur.com/ytHE0My.png)  

[Part 1](https://github.com/grijjy/DelphiCassandra) focuses on Cassandra, Part 2 focused on Couchbase and Part 3 focuses on MongoDB.

For more information about us, our support and services visit the [Grijjy homepage](http://www.grijjy.com) or the [Grijjy developers blog](http://blog.grijjy.com).

The source code and related example repository is hosted on GitHub at [https://github.com/grijjy/DelphiCassandra](https://github.com/grijjy/DelphiCassandra). 

## Introduction to Cassandra
[Apache Cassandra](http://cassandra.apache.org/) is an open-source database system that was designed to easily scale outwards in a distributed model which is common in cloud computing environments today.  Originally developed by Facebook to solve traditional performance issues related to relational databases, Cassandra uses a NoSQL approach and flexible model focused on delivering performance to reads, writes and queries.

Today Cassandra is widely used in many Internet enabled services and private organizations where scale, performance and ease of administration which is critical.  Cassandra is able to store a dynamic number of not just rows, but columns and tables which are indexed by keys which makes it highly regarded in solving problems that relate to dynamic and content without a fixed schema.

This is by no means an exhaustive look at the benefits of Cassandra.  If you are truly interested there are wealth of resources online on the how to use Cassandra and to what purpose it suits best.

## Delphi and Cassandra
To date there are very few examples of leveraging Cassandra within a Delphi application.  [One of the few examples](https://pascassa.codeplex.com/) shows the older API model (before the Cassandra CQL) using Thrift.  For our purposes here we are discussing the latest API model as of 2017 using the [CQL](http://docs.datastax.com/en/cql/3.1/cql/cql_intro_c.html).

Cassandra also has an extensive and exhaustive API library.  While we have created a header translation for most of the library (from the C library interface) we are demonstrating a basic Delphi framework only for the common CRUD related operations.

The examples here is for Delphi on Windows using a Cassandra remote database running on Linux.  We use [Ubuntu 16.04 LTS](https://www.ubuntu.com/download) for our examples.

## DataStax Cassandra Driver

This framework relies on the [DataStax C/C++ Driver](https://github.com/datastax/cpp-driver) to communicate with Cassandra.  It wraps the interface so it can be consumed by Delphi.  You can find out more information here, http://datastax.github.io/cpp-driver/ including a prepackaged installer for Windows binaries.

## Installing Cassandra Server

The official Cassandra installation instructions focus on Debian, but since we prefer Ubuntu we are only going to discuss those steps here.  Installing Cassandra involves 3 main steps:

1. Install [Ubuntu 16.04 LTS](https://www.ubuntu.com/download).
2. Install Java 8
3. Install Cassandra

### To install Java 8:
```shell
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java8-installer
```
### To install Cassandra 3.9: 
```shell
echo "deb http://www.apache.org/dist/cassandra/debian 39x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.list
```
**Note: Cassandra 3.9 is the current version, so replace the 39x above with whatever is the latest edition.** 

### Add the public key for Cassandra:
```shell
gpg --keyserver pgp.mit.edu --recv-keys 749D6EEC0353B12C
gpg --export --armor 749D6EEC0353B12C | sudo apt-key add -
```

### Update and install:
```shell
sudo apt-get update
sudo apt-get install cassandra
```
### Other tips 

#### On Ubuntu if you want Cassandra to always start when the system restarts, then type:
```shell
systemctl start cassandra
systemctl enable cassandra
```

#### To see if your single Cassandra node is operating, you can use the nodetool command:
```shell
nodetool status
```
**Note:** *The UN letters that appear before the IP address of the node, means the node is UP (U) and the node in normal (N).*

**Note:** *If you are operating a single node cluster, then **you must modify** the /etc/cassandra/cassandra.yaml and set the rpc_address to 0.0.0.0 and the broadcast_rpc_address to the IP of the server itself.*

## Hello World Example

To connect to a Cassandra cluster you provide the contact points.  In our example this is a single server's IP address, but it could be multiple nodes in a cluster or variety of other supported Cassandra related syntax.

```delphi
Cassandra := TgoCassandra.Create;
Cassandra.ContactPoints := '1.2.3.4';
if Cassandra.Connect then
begin
	// Connected
end
```

**Note:** Before you can perform any basic database operation, you must create both a Cassandra keyspace and a table.  

#### To create a keyspace:

```delphi
var
  Statement: TgoCassStatement;
begin
  Statement := TgoCassStatement.Create(
    'CREATE KEYSPACE keyspace_test WITH REPLICATION = { ''class'' : ''SimpleStrategy'', ''replication_factor'' : 1 };');
  try
    if Cassandra.Execute(Statement) then
    begin
	// Keyspace created
    end;
  finally
    Statement.Free;
  end;
end;
```

#### To create a table:

```delphi
var
  Statement: TgoCassStatement;
begin
  Statement := TgoCassStatement.Create(
    'CREATE TABLE keyspace_test.table_test (' +
        'user_id uuid,' +
        'from_user text,' +
        'time timestamp,' +
        'PRIMARY KEY (from_user, time)' +
    ')' +
    ' WITH CLUSTERING ORDER BY (time ASC);');
  try
    if Cassandra.Execute(Statement) then
    begin
      // Table created
    end;
  finally
    Statement.Free;
  end;
end;
```

#### Cassandra Uuids

Cassandra uses unique identifiers in a specialized format.  This is exposed through the TgoCassUuidGen class.

```delphi
CassUuidGen := TgoCassUuidGen.Create;
```

#### Inserting

To insert data you construct a CassStatement related to the keyspace and the table and bind the values to the statement.   The values can be simple data types, uuids or timestamps, as an example.

```delphi
var
  Statement: TgoCassStatement;
begin
  CassUuidGen := TgoCassUuidGen.Create;

  Statement := TgoCassStatement.Create('INSERT INTO keyspace_test.table_test (user_id, from_user, time) VALUES (?, ?, ?);', 3);
  try
    Statement.Bind(0, CassUuidGen.New);
    Statement.Bind(1, 'user4');
    Statement.Bind(2, gODateTimeToMillisecondsSinceEpoch(TTimeZone.Local.ToUniversalTime(Now), True));
    if Cassandra.Execute(Statement) then
    begin
      // Insert success

    end;
  finally
    Statement.Free;
  end;
end;
```

#### Query a single row

To query a single row you construct a statement and upon success, examine the first row.

```delphi
var
  Statement: TgoCassStatement;
  QueryFuture: TgoCassFuture;
  CassResult: TgoCassResult;
  Row: TgoCassRow;
begin
  Statement := TgoCassStatement.Create('SELECT * FROM keyspace_test.table_test WHERE from_user = ''user4'';');
  try
    if Cassandra.Execute(Statement, QueryFuture) then
    begin
      // Query success
      CassResult := TgoCassResult.Create(QueryFuture);
      try
        if CassResult.Success then
        begin
		  // At least one result was returned
          Row := CassResult.FirstRow;
          if Row <> nil then
          begin
            Writeln('user_id = ' + FCassUuidGen.AsString(Row.GetUuid('user_id')));
            Writeln('from_user = ' + Row.GetString('from_user'));
            Writeln('time = ' + Row.GetInt64('time').ToString);
          end;
        end;
      finally
        CassResult.Free;
      end;
    end
    else
      Writeln('Query Failure = ' + Cassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;
```

#### Query multiple rows

To query a multiple rows you construct a statement and upon success, iterate the rows.

```delphi
var
  Statement: TgoCassStatement;
  QueryFuture: TgoCassFuture;
  CassResult: TgoCassResult;
  Row: TgoCassRow;
  Iterator: TgoCassIterator;
begin
  Statement := TgoCassStatement.Create('SELECT * FROM keyspace_test.table_test;');
  try
    if Cassandra.Execute(Statement, QueryFuture) then
    begin
      // Query success
      CassResult := TgoCassResult.Create(QueryFuture);
      try
        if CassResult.Success then
        begin
          Iterator := CassResult.Iterator;
          while Iterator.Next do
          begin
            Row := Iterator.GetRow;
            Writeln('user_id = ' + FCassUuidGen.AsString(Row.GetUuid('user_id')));
            Writeln('from_user = ' + Row.GetString('from_user'));
            Writeln('time = ' + Row.GetInt64('time').ToString);
          end;
        end;
      finally
        CassResult.Free;
      end;
    end
    else
      Writeln('Query Failure = ' + Cassandra.LastErrorDesc);
  finally
    Statement.Free;
  end;
end;
```

#### Handling errors

If a method fails the the ```Cassandra.LastErrorDesc``` and ```Cassandra.LastErrorCode``` will be updated with error related information.

## License

TgoCassandra and DelphiCassandra is licensed under the Simplified BSD License. See License.txt for details.