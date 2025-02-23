package EventsApp::Controller::EventLinks;
use Mojo::Base 'Mojolicious::Controller';

sub list {
    my $self = shift;
    my $sth = $self->db->dbh->prepare(qq{
        SELECT e.* 
        FROM events e
        JOIN event_links el ON e.evt_id = el.evt_id_2
        WHERE el.evt_id_1 = ?
        UNION
        SELECT e.* 
        FROM events e
        JOIN event_links el ON e.evt_id = el.evt_id_1
        WHERE el.evt_id_2 = ?
    });
    $sth->execute($self->param('event_id'), $self->param('event_id'));
    $self->render(json => $sth->fetchall_arrayref({}));
}

sub create {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare('INSERT INTO event_links (evt_id_1, evt_id_2) VALUES (?, ?)');
    $sth->execute($data->{evt_id_1}, $data->{evt_id_2});
    $self->render(json => { success => 1 });
}

sub delete {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare('DELETE FROM event_links WHERE evt_id_1 = ? AND evt_id_2 = ?');
    $sth->execute($data->{evt_id_1}, $data->{evt_id_2});
    $self->render(json => { success => 1 });
}

1;

