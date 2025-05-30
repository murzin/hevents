# lib/EventsApp.pm
package EventsApp;
use Mojo::Base 'Mojolicious';
use EventsApp::Model::DB;

sub startup {
    my $self = shift;

    # Configure database
    $self->helper(db => sub {
        state $db = EventsApp::Model::DB->new(
            dsn => "dbi:SQLite:dbname=db/hevents.db",
            username => "",
            password => ""
        );
    });

    # Configure routes
    my $r = $self->routes;
    
    # Serve static files from "public/" automatically
    $r->get('/' => sub {
        my $c = shift;
        $c->reply->static('index.html');
    });
    $r->get('/backend' => sub {
        my $c = shift;
        $c->reply->static('backend.html');
    });
    
    # static jsons
    $r->get('/events.json' => sub {
        my $c = shift;
        $c->reply->static('events.json');
    });
    $r->get('/event_types.json' => sub {
        my $c = shift;
        $c->reply->static('event_types.json');
    });
    $r->get('/event_places.json' => sub {
        my $c = shift;
        $c->reply->static('event_places.json');
    });

    # API routes
    my $api = $r->under('/api');
    
    # Event Types
    $api->get('/event_types')->to('event_types#list');
    $api->post('/event_types')->to('event_types#create');
    $api->get('/event_types/:id')->to('event_types#get');
    $api->delete('/event_types/:id')->to('event_types#delete');
    
    # Event Places
    $api->get('/event_places')->to('event_places#list');
    $api->post('/event_places')->to('event_places#create');
    $api->get('/event_places/:id')->to('event_places#get');
    $api->delete('/event_places/:id')->to('event_places#delete');
    
    # Events
    $api->get('/events')->to('events#list');
    $api->post('/events')->to('events#create');
    $api->get('/events/:id')->to('events#get');
    $api->delete('/events/:id')->to('events#delete');
    $api->put('/events/:id')->to('events#put');
    
    # Event Links
    $api->get('/event_links/:event_id')->to('event_links#list');
    $api->post('/event_links')->to('event_links#create');
    $api->delete('/event_links')->to('event_links#delete');
}

1;
