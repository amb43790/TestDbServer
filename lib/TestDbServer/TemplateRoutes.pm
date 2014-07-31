package TestDbServer::TemplateRoutes;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;
use File::Basename;

use TestDbServer::Command::SaveTemplateFile;

sub list {
    my $self = shift;

    my $templates = $self->app->db_storage->search_template;
    my @ids;
    while(my $tmpl = $templates->next) {
        push @ids, $tmpl->template_id;
    }
    $self->render(json => \@ids);
}

sub get {
    my $self = shift;

    my $id = $self->stash('id');
    my $schema = $self->app->db_storage;

    my $template = $schema->find_template($id);
    if ($template) {
        my %template = map { $_ => $template->$_ } qw(template_id name owner note file_path create_time last_used_time);
        $self->render(json => \%template);
    } else {
        $self->render_not_found;
    }
}

sub save {
    my $self = shift;

    my $id = $self->stash('id');
    if ($self->stash('based_on')) {
        $self->_save_based_on();
    } else {
        $self->_save_file();
    }
}

sub _save_file {
    my $self = shift;

    my $schema = $self->app->db_storage;
    my($template_id, $return_code);
    try {
        my $cmd = TestDbServer::Command::SaveTemplateFile->new(
                name => $self->param('name') || undef,
                owner => $self->param('owner') || undef,
                note => $self->param('note') || undef,
                upload => $self->req->upload('file'),
                schema => $schema,
                file_storage => $self->app->file_storage,
            );

        $schema->txn_do(sub {
            $template_id = $cmd->execute();
            $return_code = 201;
        });
    }
    catch {
        if ((ref($_) && $_->isa('Exception::FileExists'))
            ||
            (ref($_) && $_->isa('DBIx::Class::Exception') && $_ =~ m/UNIQUE constraint failed/i)
        ) {
            $return_code = 403;
        } else {
            $self->app->log->error("save_file: $_");
            $return_code = 500;
        }
    };

    if ($template_id) {
        my $response_location = join('/', $self->req->url, $template_id);
        $self->res->headers->location($response_location);
    }

    $self->rendered($return_code);
}

sub _save_based_on {
    my $self = shift;

}

sub delete {
    my $self = shift;

    my $id = $self->stash('id');
    my $schema = $self->app->db_storage;

    my $return_code;
    try {
        $schema->txn_do(sub {
            $schema->delete_template($id);
            $return_code = 204;
        });
    }
    catch {
        $return_code = 404;
    };

    $self->rendered($return_code);
}

1;
