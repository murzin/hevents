package EventsApp::Controller::EventTypes;
use Mojo::Base 'Mojolicious::Controller';

sub list {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('SELECT * FROM event_types');
    $sth->execute();
    $self->render(json => $sth->fetchall_arrayref({}));
}

sub create {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare('INSERT INTO event_types (etp_name) VALUES (?)');
    $sth->execute($data->{etp_name});
    $self->render(json => { id => $self->db->dbh->last_insert_id() });
}

sub get {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('SELECT * FROM event_types WHERE etp_id = ?');
    $sth->execute($self->param('id'));
    my $result = $sth->fetchrow_hashref();
    $self->render(json => $result || {});
}

sub delete {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('DELETE FROM event_types WHERE etp_id = ?');
    $sth->execute($self->param('id'));
    $self->render(json => { success => 1 });
}

1;
