use TestDbServer::Schema;
use TestDbServer::FileStorage;
use TestDbServer::Configuration;

package TestDbServer;

use Moose;
use MooseX::NonMoose;
extends 'Mojolicious';

has db_storage => (
    is => 'ro',
    isa => 'TestDbServer::Schema',
    lazy_build => 1,
);
has file_storage => (
    is => 'ro',
    isa => 'TestDbServer::FileStorage',
    lazy_build => 1,
);
has configuration => (
    is => 'rw',
    isa => 'TestDbServer::Configuration',
    lazy_build => 1,
);

# This method will run once at server start
sub startup {
    my $self = shift;

    $self->_setup_routes();
}

sub _setup_routes {
    my $self = shift;

    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('info#root');

    $r->get('/templates')->to('template_routes#list');
    $r->get('/templates/:id')->to('template_routes#get');
    $r->post('/templates')->to('template_routes#save');
    $r->delete('/templates/:id')->to('template_routes#delete');

    $r->get('/databases')->to('database_routes#list');
    $r->post('/databases')->to('database_routes#create');
    $r->get('/databases/:id')->to('database_routes#get');
    $r->patch('/databases/:id')->to('database_routes#patch');
    $r->delete('/databases/:id')->to('database_routes#delete');
}

sub _build_db_storage {
    my $self = shift;

    TestDbServer::Schema->initialize($self);

    TestDbServer::Schema->connect(
            $self->configuration->db_connect_string,
            $self->configuration->db_user,
            $self->configuration->db_password,
        );
}

sub _build_file_storage {
    my $self = shift;

    my $base_path = $self->configuration->file_storage_path;
    TestDbServer::FileStorage->new(base_path => $base_path, app => $self);
}

sub _build_configuration {
    my $self = shift;
    my $config = $self->plugin('Config');
    TestDbServer::Configuration->new_from_app_config($config);
}

1;