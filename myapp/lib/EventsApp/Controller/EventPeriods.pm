package EventsApp::Controller::EventPeriods;
use Mojo::Base 'Mojolicious::Controller';

sub list {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('SELECT * FROM event_periods');
    $sth->execute();
    $self->render(json => $sth->fetchall_arrayref({}));
}

sub create {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare('INSERT INTO event_periods (epr_name) VALUES (?)');
    $sth->execute($data->{epr_name});
    $self->render(json => { id => $self->db->dbh->last_insert_id() });
}

sub update {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare('UPDATE event_periods set epr_name = ? where epr_id = ?'); 
    $sth->execute($data->{epr_name}, $data->{epr_id});
    $self->render(json => { id => $data->{epr_id} });
}

sub get {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('SELECT * FROM event_periods WHERE epr_id = ?');
    $sth->execute($self->param('id'));
    my $result = $sth->fetchrow_hashref();
    $self->render(json => $result || {});
}

sub delete {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('DELETE FROM event_periods WHERE epr_id = ?');
    $sth->execute($self->param('id'));
    $self->render(json => { success => 1 });
}

1;
