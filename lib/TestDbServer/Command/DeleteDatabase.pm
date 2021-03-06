package TestDbServer::Command::DeleteDatabase;

use TestDbServer::PostgresInstance;
use TestDbServer::Exceptions;

use Moose;

has database_id => ( isa => 'Str', is => 'ro', required => 1 );
has schema => (isa => 'TestDbServer::Schema', is => 'ro', required => 1 );

no Moose;

sub execute {
    my $self = shift;

    my $database = $self->schema->find_database($self->database_id);
    unless ($database) {
        Exception::DatabaseNotFound->throw(database_id => $self->database_id);
    }

    my $pg = TestDbServer::PostgresInstance->new(
                        name => $database->name,
                        host => $database->host,
                        port => $database->port,
                        owner => $database->owner,
                    );

    $pg->dropdb();

    $database->delete();

    return 1;
}

1;
