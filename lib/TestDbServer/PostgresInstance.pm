use App::Info::RDBMS::PostgreSQL;
use Data::UUID;

use TestDbServer::Exceptions;

package TestDbServer::PostgresInstance;

use Moose;

has 'host' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'port' => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);
has 'owner' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'superuser' => (
    is => 'ro',
    isa => 'Str',
);
has 'name' => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);
{
    my $app_pg = App::Info::RDBMS::PostgreSQL->new();
    sub app_pg { return $app_pg }
}

sub createdb {
    my $self = shift;

    my $createdb = $self->app_pg->createdb;

    my $host = $self->host;
    my $port = $self->port;
    my $owner = $self->owner;
    my $superuser = $self->superuser;
    my $name = $self->name;

    unless ($superuser) {
        Exception::SuperuserRequired->throw();
    }

    my $output = `$createdb -h $host -p $port -U $superuser -O $owner $name 2>&1`;
    if ($? != 0) {
        Exception::CannotCreateDatabase->throw(error => "$createdb failed", output => $output, child_error => $?);
    }
    return 1;
}

my $uuid_gen = Data::UUID->new();
sub _build_name {
    my $class = shift;
    my $hex = $uuid_gen->create_hex();
    $hex =~ s/^0x//;
    return $hex;
}

sub dropdb {
    my $self = shift;
    my $dropdb = $self->app_pg->dropdb;

    my $host = $self->host;
    my $port = $self->port;
    my $owner = $self->owner;
    my $name = $self->name;

    my $output = `$dropdb -h $host -p $port -U $owner $name 2>&1`;
    if ($? != 0) {
        Exception::CannotDropDatabase->throw(error => "$dropdb failed", output => $output, child_error => $?);
    }
    return 1;
}

sub exportdb {
    my($self, $filename) = @_;

    my $pg_dump = $self->app_pg->pg_dump;

    my $host = $self->host;
    my $port = $self->port;
    my $owner = $self->owner;
    my $name = $self->name;

    my $output = qx($pg_dump -h $host -p $port -U $owner -f $filename $name 2>&1);
    if ($? != 0) {
        Exception::CannotExportDatabase->throw(error => "$pg_dump failed", output => $output, child_error => $?);
    }
    return 1;
}

sub importdb {
    my($self, $filename) = @_;

    my $psql = $self->app_pg->psql;

    my $host = $self->host;
    my $port = $self->port;
    my $owner = $self->owner;
    my $name = $self->name;

    my $output = qx($psql -h $host -p $port -U $owner -d $name -f $filename --set=ON_ERROR_STOP=1 2>&1);
    if ($? != 0) {
        Exception::CannotImportDatabase->throw(error => "$psql failed", output => $output, child_error => $?);
    }
    return 1;
}

1;
