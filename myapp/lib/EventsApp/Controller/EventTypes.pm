package EventsApp::Controller::EventTypes;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw(decode_json);

sub list {
    my $self = shift;
    my $results = $self->sqlite->db->query('SELECT * FROM event_types');
    $self->render(json => $results->hashes->to_array);
}

sub get {
    my $self = shift;
    my $id = $self->param('id');
    my $result = $self->sqlite->db->query('SELECT * FROM event_types WHERE etp_id = ?', $id)->hash;
    
    return $self->render(json => {error => 'Event type not found'}, status => 404)
        unless $result;
    
    $self->render(json => $result);
}

sub create {
    my $self = shift;
    my $data = $self->req->json;
    
    eval {
        my $result = $self->sqlite->db->query('INSERT INTO event_types (etp_name) VALUES (?) RETURNING etp_id, etp_name',
            $data->{etp_name})->hash;
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
        my $result = $self->sqlite->db->query('UPDATE event_types SET etp_name = ? WHERE etp_id = ? RETURNING etp_id, etp_name',
            $data->{etp_name}, $id)->hash;
            
        return $self->render(json => {error => 'Event type not found'}, status => 404)
            unless $result;
            
        $self->render(json => $result);
    } or do {
        $self->render(json => {error => $@}, status => 400);
    };
}

sub delete {
    my $self = shift;
    my $id = $self->param('id');
    
    my $result = $self->sqlite->db->query('DELETE FROM event_types WHERE etp_id = ? RETURNING etp_id', $id)->hash;
    
    return $self->render(json => {error => 'Event type not found'}, status => 404)
        unless $result;
        
    $self->render(json => {message => 'Event type deleted'});
}

1;

