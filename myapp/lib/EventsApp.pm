#!/usr/bin/env perl
# lib/EventsApp.pm
package EventsApp;
use Mojo::Base 'Mojolicious';
use Mojo::SQLite;

sub startup {
    my $self = shift;
    
    # Configure SQLite
    my $sqlite = Mojo::SQLite->new('sqlite:db/hevents.db');
    $self->helper(sqlite => sub { $sqlite });
    
    # Initialize database
    $sqlite->db->query(q{
        CREATE TABLE IF NOT EXISTS event_types (
            etp_id INTEGER PRIMARY KEY,
            etp_name TEXT NOT NULL
        )
    });
    
    $sqlite->db->query(q{
        CREATE TABLE IF NOT EXISTS events (
            evt_id INTEGER PRIMARY KEY,
            evt_name TEXT NOT NULL,
            evt_desc TEXT,
            evt_url TEXT,
            evt_from TEXT NOT NULL,
            evt_to TEXT NOT NULL,
            etp_id INTEGER NOT NULL,
            FOREIGN KEY (etp_id) REFERENCES event_types(etp_id) ON DELETE CASCADE
        )
    });

    $sqlite->db->query(q{
        CREATE TABLE IF NOT EXISTS event_links (
            evt_id_1 INTEGER NOT NULL,
            evt_id_2 INTEGER NOT NULL,
            PRIMARY KEY (evt_id_1, evt_id_2),
            FOREIGN KEY (evt_id_1) REFERENCES events(evt_id) ON DELETE CASCADE,
            FOREIGN KEY (evt_id_2) REFERENCES events(evt_id) ON DELETE CASCADE
        )
    });



    # Routes
    my $r = $self->routes;
    
    # Event Types Routes
    $r->get('/api/event_types')->to('event_types#list');
    $r->post('/api/event_types')->to('event_types#list');
    $r->get('/api/event_types/:id')->to('event_types#get');
    $r->post('/api/event_types')->to('event_types#create');
    $r->put('/api/event_types/:id')->to('event_types#update');
    $r->delete('/api/event_types/:id')->to('event_types#delete');
    
    # Events Routes
    $r->get('/api/events')->to('events#list');
    $r->get('/api/events/:id')->to('events#get');
    $r->post('/api/events')->to('events#create');
    $r->put('/api/events/:id')->to('events#update');
    $r->delete('/api/events/:id')->to('events#delete');

    # Event Links Routes
    $r->get('/api/events/:id/links')->to('events#list_links');
    $r->post('/api/events/:id/links/:target_id')->to('events#add_link');
    $r->delete('/api/events/:id/links/:target_id')->to('events#remove_link');
    
}

1;

