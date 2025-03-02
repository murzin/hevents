package EventsApp::Controller::Events;
use Mojo::Base 'Mojolicious::Controller';
use Encode;

sub list {
    my $self = shift;
    my $sth = $self->db->dbh->prepare(qq{
        SELECT e.*, et.etp_name, ep.epl_name 
        FROM events e
        JOIN event_types et ON e.etp_id = et.etp_id
        JOIN event_places ep ON e.epl_id = ep.epl_id
    });
    $sth->execute();

    #$self->render(json => $sth->fetchall_arrayref({}));
    my $arr = $sth->fetchall_arrayref({});
    for (@$arr) {
        $_->{evt_name} = decode_utf8($_->{evt_name});
        $_->{evt_from} = substr($_->{evt_from}, 0, 4);
        $_->{evt_to} = substr($_->{evt_to}, 0, 4);
        my $links = [];
        my $sth = $self->db->dbh->prepare(qq{
            SELECT el.evt_id_2, e.evt_name
            FROM event_links el
            LEFT JOIN events e on (e.evt_id = el.evt_id_2)
            WHERE el.evt_id_1 = ?
        });
        $sth->execute($_->{evt_id});
        push @$links, [ $_->[0], $_->[1] ] for @{ $sth->fetchall_arrayref };
        $sth = $self->db->dbh->prepare(qq{
            SELECT el.evt_id_1, e.evt_name
            FROM event_links el
            LEFT JOIN events e on (e.evt_id = el.evt_id_1)
            WHERE el.evt_id_2 = ?
        });
        $sth->execute($_->{evt_id});
        push @$links, [ $_->[0], $_->[1] ]  for @{ $sth->fetchall_arrayref };
        $_->{links} = $links;
    }
    $self->render(json => $arr);

}

sub create {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare(qq{
        INSERT INTO events 
        (evt_name, evt_desc, evt_url, evt_from, evt_to, etp_id, epl_id)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    });
    $sth->execute(
        $data->{evt_name},
        $data->{evt_desc},
        $data->{evt_url},
        $data->{evt_from},
        $data->{evt_to},
        $data->{etp_id},
        $data->{epl_id}
    );
    $self->render(json => { id => $self->db->dbh->last_insert_id() });
}

sub get {
    my $self = shift;
    my $sth = $self->db->dbh->prepare(qq{
        SELECT e.*, et.etp_name, ep.epl_name 
        FROM events e
        JOIN event_types et ON e.etp_id = et.etp_id
        JOIN event_places ep ON e.epl_id = ep.epl_id
        WHERE e.evt_id = ?
    });
    $sth->execute($self->param('id'));
    my $result = $sth->fetchrow_hashref();
    $self->render(json => $result || {});
}

sub delete {
    my $self = shift;
    my $sth = $self->db->dbh->prepare('DELETE FROM events WHERE evt_id = ?');
    $sth->execute($self->param('id'));
    $self->render(json => { success => 1 });
}

sub put {
    my $self = shift;
    my $data = $self->req->json;
    my $sth = $self->db->dbh->prepare('
        UPDATE events
        SET evt_name = ?, evt_desc = ?, evt_url = ?, evt_from = ?, evt_to = ?, etp_id = ?, epl_id = ?
        WHERE evt_id = ?
    ');
    $sth->execute(
        $data->{evt_name},
        $data->{evt_desc},
        $data->{evt_url},
        $data->{evt_from},
        $data->{evt_to},
        $data->{etp_id},
        $data->{epl_id},
        $self->param('id'),
    );
    $self->render(json => { success => 1 });
}

1;
