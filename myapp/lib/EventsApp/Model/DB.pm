package EventsApp::Model::DB;
use Mojo::Base -base;
use DBI;

has 'dsn';
has 'username';
has 'password';
has 'dbh' => sub {
    my $self = shift;
    my $dbh = DBI->connect(
        $self->dsn,
        $self->username,
        $self->password,
        { RaiseError => 1, sqlite_foreign_keys => 1 }
    );
    return $dbh;
};

1;

