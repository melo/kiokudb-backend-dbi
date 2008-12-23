#!/usr/bin/perl

use Test::More;

BEGIN {
    plan skip_all => "DBD::SQLite is required" unless eval { require DBI; require DBD::SQLite };
    plan 'no_plan';
}

use Test::TempDir;

use ok 'KiokuDB';
use ok 'KiokuDB::Backend::DBI';

use KiokuDB::Test;

use Search::GIN::Extract::Class;

my $sqlite = "dbi:SQLite:dbname=" . temp_root->file("db");

foreach my $dsn (
    [ $sqlite ],
    #[ "dbi:mysql:test" ],
    #[ "dbi:Pg:dbname=test" ],
) {
    foreach my $serializer (qw(json storable), eval { require YAML::XS; "yaml" }) {
        diag "testing against $dsn->[0] with $serializer\n";

        my $dir = KiokuDB->connect(
            @$dsn,
            create => 1,
            serializer => $serializer,
            columns => [
                name => {
                    is_nullable => 1,
                    data_type   => "varchar",
                },
                age => {
                    is_nullable => 1,
                    data_type   => "integer",
                },
            ],
            extract => Search::GIN::Extract::Class->new,
        );

        $dir->txn_do(sub { $dir->backend->clear });

        run_all_fixtures($dir);

        $dir->txn_do(sub { $dir->backend->drop_tables });
    }
}
