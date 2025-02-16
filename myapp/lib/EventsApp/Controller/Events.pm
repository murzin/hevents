package EventsApp::Controller::Events;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);

sub list {
    my $self = shift;
    my $data = $self->req->json || {};
    my $from_date = $self->param('from');
    my $to_date = $self->param('to');
    
    my $query = q{
        SELECT e.*, et.etp_name 
        FROM events e 
        JOIN event_types et ON e.etp_id = et.etp_id
        WHERE 1=1
    };
    my @params;
    
    # Handle evt_id filtering
    if ($data->{evt_id}) {
        my @ids = ref $data->{evt_id} eq 'ARRAY' ? @{$data->{evt_id}} : ($data->{evt_id});
        if (@ids) {
            my $placeholders = join(',', ('?') x @ids);
            $query .= " AND e.evt_id IN ($placeholders)";
            push @params, @ids;
        }
    }
    
    # Handle date filtering
    if ($from_date) {
        $query .= " AND e.evt_from >= ?";
        push @params, $from_date;
    }
    
    if ($to_date) {
        $query .= " AND e.evt_to <= ?";
        push @params, $to_date;
    }
    
    # Add ordering
    $query .= " ORDER BY e.evt_from, e.evt_id";
    
    my $results = $self->sqlite->db->query($query, @params);
    $self->render(json => $results->hashes->to_array);
}

sub get {
    my $self = shift;
    my $id = $self->param('id');
    my $result = $self->sqlite->db->query(q{
        SELECT e.*
        FROM events e 
        WHERE e.evt_id = ?
    }, $id)->hash;
    
    return $self->render(json => {error => 'Event not found'}, status => 404)
        unless $result;

# Get linked events
    my $linked_events = $self->sqlite->db->query(q{
        SELECT e.*
        FROM events e
        JOIN event_links el ON (e.evt_id = el.evt_id_1 OR e.evt_id = el.evt_id_2)
        WHERE (el.evt_id_1 = ? OR el.evt_id_2 = ?)
        AND e.evt_id != ?
    }, $id, $id, $id)->hashes->to_array;
    
    $result->{linked_events} = $linked_events;
    
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

sub list_links {
    my $self = shift;
    my $id = $self->param('id');
    
    my $linked_events = $self->sqlite->db->query(q{
        SELECT e.*
        FROM events e
        JOIN event_links el ON (e.evt_id = el.evt_id_1 OR e.evt_id = el.evt_id_2)
        WHERE (el.evt_id_1 = ? OR el.evt_id_2 = ?)
        AND e.evt_id != ?
    }, $id, $id, $id)->hashes->to_array;
    
    $self->render(json => $linked_events);
}

sub add_link {
    my $self = shift;
    my $id = $self->param('id');
    my $target_id = $self->param('target_id');
    
    return $self->render(json => {error => 'Cannot link event to itself'}, status => 400)
        if $id == $target_id;
    
    eval {
        $self->sqlite->db->query(q{
            INSERT INTO event_links (evt_id_1, evt_id_2)
            VALUES (?, ?)
        }, $id < $target_id ? ($id, $target_id) : ($target_id, $id));
        
        $self->render(json => {message => 'Link created'}, status => 201);
    } or do {
        $self->render(json => {error => $@}, status => 400);
    };
}

sub remove_link {
    my $self = shift;
    my $id = $self->param('id');
    my $target_id = $self->param('target_id');
    
    my $result = $self->sqlite->db->query(q{
        DELETE FROM event_links 
        WHERE (evt_id_1 = ? AND evt_id_2 = ?)
           OR (evt_id_1 = ? AND evt_id_2 = ?)
        RETURNING evt_id_1
    }, $id, $target_id, $target_id, $id)->hash;
    
    return $self->render(json => {error => 'Link not found'}, status => 404)
        unless $result;
    
    $self->render(json => {message => 'Event link deleted'});
}



1;

