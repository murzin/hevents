package EventsApp::Controller::Events;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);

sub list {
    my $self = shift;
    my $from_date = $self->param('from');
    my $to_date = $self->param('to');

    my $query = q{
        SELECT e.*, et.etp_name
        FROM events e
        JOIN event_types et ON e.etp_id = et.etp_id
        WHERE 1=1
    };
    my @params;

    if ($from_date) {
        $query .= " AND e.evt_from >= ?";
        push @params, $from_date;
    }

    if ($to_date) {
        $query .= " AND e.evt_to <= ?";
        push @params, $to_date;
    }

    my $results = $self->sqlite->db->query($query, @params);
    $self->render(json => $results->hashes->to_array);
}

sub get {
    my $self = shift;
    my $id = $self->param('id');
    my $result = $self->sqlite->db->query(q{
        SELECT e.*, et.etp_name 
        FROM events e 
        JOIN event_types et ON e.etp_id = et.etp_id 
        WHERE evt_id = ?
    }, $id)->hash;
    
    return $self->render(json => {error => 'Event not found'}, status => 404)
        unless $result;
    
    $self->render(json => $result);
}

sub create {
    my $self = shift;
    my $data = $self->req->json;
    
    eval {
        my $result = $self->sqlite->db->query(q{
            INSERT INTO events (evt_name, evt_desc, evt_url, evt_from, evt_to, etp_id) 
            VALUES (?, ?, ?, ?, ?, ?) 
            RETURNING evt_id, evt_name, evt_desc, evt_url, evt_from, evt_to, etp_id
        }, $data->{evt_name}, $data->{evt_desc}, $data->{evt_url}, 
           $data->{evt_from}, $data->{evt_to}, $data->{etp_id})->hash;
        
        $self->render(json => $result, status => 201);
    } or do {
        $self->render(json => {error => $@}, status => 400);
    };
}

sub update {
    my $self = shift;
    my $id = $self->param('id');
    my $data = $self->req->json;
    
    eval {
        my $result = $self->sqlite->db->query(q{
            UPDATE events 
            SET evt_name = ?, evt_desc = ?, evt_url = ?, evt_from = ?, evt_to = ?, etp_id = ? 
            WHERE evt_id = ?
            RETURNING evt_id, evt_name, evt_desc, evt_url, evt_from, evt_to, etp_id
        }, $data->{evt_name}, $data->{evt_desc}, $data->{evt_url},
           $data->{evt_from}, $data->{evt_to}, $data->{etp_id}, $id)->hash;
        
        return $self->render(json => {error => 'Event not found'}, status => 404)
            unless $result;
            
        $self->render(json => $result);
    } or do {
        $self->render(json => {error => $@}, status => 400);
    };
}

sub delete {
    my $self = shift;
    my $id = $self->param('id');
    
    my $result = $self->sqlite->db->query('DELETE FROM events WHERE evt_id = ? RETURNING evt_id', $id)->hash;
    
    return $self->render(json => {error => 'Event not found'}, status => 404)
        unless $result;
        
    $self->render(json => {message => 'Event deleted'});
}

1;

