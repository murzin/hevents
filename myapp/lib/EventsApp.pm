# lib/EventsApp.pm
package EventsApp;
use Mojo::Base 'Mojolicious', -signatures;
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
    $r->get('/event_periods.json' => sub {
        my $c = shift;
        $c->reply->static('event_periods.json');
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
    
    # Event Periods
    $api->get('/event_periods')->to('event_periods#list');
    $api->post('/event_periods')->to('event_periods#create');
    $api->get('/event_periods/:id')->to('event_periods#get');
    $api->delete('/event_periods/:id')->to('event_periods#delete');
    
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

    _admin_routes($self);
}

sub _admin_routes ($self) {
  my $r = $self->routes;

  #$r->get('/')->to(cb => sub ($c) { $c->reply->static('index.html') });
  #$r->get('/backend')->to(cb => sub ($c) { $c->reply->static('backend.html') });
  $r->get('/admin')->to(cb => sub ($c) {
    my %counts;
    $counts{$_} = 0 + $c->db->dbh->selectrow_array("SELECT COUNT(*) FROM $_")
      for qw(events event_types event_places event_periods event_links);
    $c->stash(counts => \%counts);
    $c->render(template => 'admin/dashboard');
  });

  _admin_simple($self, 'event_types', 'etp_id', 'etp_name', 'Event types', 'event type', 1);
  _admin_simple($self, 'event_places', 'epl_id', 'epl_name', 'Event places', 'event place', 1);
  _admin_simple($self, 'event_periods', 'epr_id', 'epr_name', 'Event periods', 'event period');

  $r->get('/admin/events')->to(cb => sub ($c) {
    my %filters;
    my (@where, @bind);
    my $query = $c->param('q') // '';
    $query =~ s/^\s+|\s+$//g;
    if (length $query) {
      $filters{q} = $query;
      push @where, 'INSTR(LOWER(e.evt_name), LOWER(?)) > 0';
      push @bind, $query;
    }
    for my $filter (
      [etp_id => 'e.etp_id'],
      [epl_id => 'e.epl_id'],
      [epr_id => 'e.epr_id']
    ) {
      my ($param, $column) = @$filter;
      my $value = $c->param($param) // '';
      next unless $value =~ /^\d+$/ && $value > 0;
      $filters{$param} = $value;
      push @where, "$column = ?";
      push @bind, $value;
    }
    my $where = @where ? ' WHERE ' . join(' AND ', @where) : '';
    my $total = 0 + $c->db->dbh->selectrow_array(
      "SELECT COUNT(*) FROM events e$where", undef, @bind
    );
    my $pager = _pagination($c, $total);
    my $sql = q{
      SELECT e.*, t.etp_name, p.epl_name, r.epr_name
      FROM events e
      JOIN event_types t ON t.etp_id = e.etp_id
      JOIN event_places p ON p.epl_id = e.epl_id
      JOIN event_periods r ON r.epr_id = e.epr_id
    } . $where . q{
      ORDER BY e.evt_id
      LIMIT ? OFFSET ?
    };
    my $events = $c->db->dbh->selectall_arrayref(
      $sql, {Slice => {}}, @bind, $pager->{per_page}, $pager->{offset}
    );
    _event_form_data($c);
    $c->stash(
      events => $events, pager => $pager, path => '/admin/events',
      filters => \%filters
    );
    $c->render(template => 'admin/events');
  });
  $r->get('/admin/events/new')->to(cb => sub ($c) {
    _event_form_data($c);
    $c->stash(event => {}, form_action => '/admin/events', form_title => 'New event');
    $c->render(template => 'admin/event_form');
  });
  $r->post('/admin/events')->to(cb => sub ($c) {
    my @fields = qw(evt_name evt_desc evt_url evt_from evt_to etp_id epl_id epr_id);
    return _admin_error($c, '/admin/events/new', 'All event fields are required')
      if grep { !defined $c->param($_) || $c->param($_) eq '' } @fields;
    return _admin_write($c, '/admin/events', 'Event created', sub {
      $c->db->dbh->do(q{
        INSERT INTO events
          (evt_name, evt_desc, evt_url, evt_from, evt_to, etp_id, epl_id, epr_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      }, undef, map {$c->param($_)} @fields);
    });
  });
  $r->get('/admin/events/:id/edit')->to(cb => sub ($c) {
    my $event = $c->db->dbh->selectrow_hashref(
      'SELECT * FROM events WHERE evt_id = ?', undef, $c->param('id')
    );
    return $c->reply->not_found unless $event;
    _event_form_data($c);
    $c->stash(
      event => $event,
      form_action => '/admin/events/' . $event->{evt_id},
      form_title => 'Edit event'
    );
    $c->render(template => 'admin/event_form');
  });
  $r->post('/admin/events/:id')->to(cb => sub ($c) {
    my @fields = qw(evt_name evt_desc evt_url evt_from evt_to etp_id epl_id epr_id);
    return _admin_error($c, '/admin/events/' . $c->param('id') . '/edit', 'All event fields are required')
      if grep { !defined $c->param($_) || $c->param($_) eq '' } @fields;
    return _admin_write($c, '/admin/events', 'Event updated', sub {
      $c->db->dbh->do(q{
        UPDATE events
        SET evt_name=?, evt_desc=?, evt_url=?, evt_from=?, evt_to=?,
            etp_id=?, epl_id=?, epr_id=?
        WHERE evt_id=?
      }, undef, (map {$c->param($_)} @fields), $c->param('id'));
    });
  });
  $r->post('/admin/events/:id/delete')->to(cb => sub ($c) {
    _admin_write($c, '/admin/events', 'Event deleted', sub {
      $c->db->dbh->do('DELETE FROM events WHERE evt_id = ?', undef, $c->param('id'));
    });
  });

  $r->get('/admin/event-links')->to(cb => sub ($c) {
    my $total = 0 + $c->db->dbh->selectrow_array('SELECT COUNT(*) FROM event_links');
    my $pager = _pagination($c, $total);
    my $links = $c->db->dbh->selectall_arrayref(q{
      SELECT l.evt_id_1, a.evt_name AS evt_name_1,
             l.evt_id_2, b.evt_name AS evt_name_2
      FROM event_links l
      JOIN events a ON a.evt_id = l.evt_id_1
      JOIN events b ON b.evt_id = l.evt_id_2
      ORDER BY l.evt_id_1, l.evt_id_2
      LIMIT ? OFFSET ?
    }, {Slice => {}}, $pager->{per_page}, $pager->{offset});
    my $events = $c->db->dbh->selectall_arrayref(
      'SELECT evt_id, evt_name FROM events ORDER BY evt_name', {Slice => {}}
    );
    $c->stash(
      links => $links, events => $events, pager => $pager,
      path => '/admin/event-links'
    );
    $c->render(template => 'admin/event_links');
  });
  $r->post('/admin/event-links')->to(cb => sub ($c) {
    my ($a, $b) = sort {$a <=> $b} ($c->param('evt_id_1'), $c->param('evt_id_2'));
    return _admin_error($c, '/admin/event-links', 'Choose two different events') if $a == $b;
    _admin_write($c, '/admin/event-links', 'Event link created', sub {
      $c->db->dbh->do(
        'INSERT INTO event_links (evt_id_1, evt_id_2) VALUES (?, ?)', undef, $a, $b
      );
    });
  });
  $r->post('/admin/event-links/:a/:b/delete')->to(cb => sub ($c) {
    _admin_write($c, '/admin/event-links', 'Event link deleted', sub {
      $c->db->dbh->do(
        'DELETE FROM event_links WHERE evt_id_1=? AND evt_id_2=?',
        undef, $c->param('a'), $c->param('b')
      );
    });
  });
}

sub _admin_simple ($self, $table, $id_col, $name_col, $title, $singular, $with_period = 0) {
  my $r = $self->routes;
  my $path = "/admin/$table";
  $r->get($path)->to(cb => sub ($c) {
    my $total = 0 + $c->db->dbh->selectrow_array("SELECT COUNT(*) FROM $table");
    my $pager = _pagination($c, $total);
    my $select = $with_period
      ? "$table.$id_col, $table.$name_col, $table.epr_id, event_periods.epr_name"
      : "$table.$id_col, $table.$name_col";
    my $join = $with_period
      ? ' LEFT JOIN event_periods ON event_periods.epr_id = ' . $table . '.epr_id'
      : '';
    my $rows = $c->db->dbh->selectall_arrayref(
      "SELECT $select FROM $table$join ORDER BY $table.$id_col LIMIT ? OFFSET ?",
      {Slice => {}}, $pager->{per_page}, $pager->{offset}
    );
    my $periods = $with_period
      ? $c->db->dbh->selectall_arrayref(
          'SELECT epr_id, epr_name FROM event_periods ORDER BY epr_name',
          {Slice => {}}
        )
      : [];
    $c->stash(
      rows => $rows, id_col => $id_col, name_col => $name_col,
      title => $title, singular => $singular, path => $path, pager => $pager,
      with_period => $with_period, periods => $periods
    );
    $c->render(template => 'admin/simple');
  });
  $r->post($path)->to(cb => sub ($c) {
    return _admin_error($c, $path, 'Name is required')
      unless defined $c->param($name_col) && $c->param($name_col) ne '';
    return _admin_error($c, $path, 'Period is required')
      if $with_period && (($c->param('epr_id') // '') !~ /^\d+$/);
    _admin_write($c, $path, ucfirst($singular) . ' created', sub {
      if ($with_period) {
        $c->db->dbh->do(
          "INSERT INTO $table ($name_col, epr_id) VALUES (?, ?)",
          undef, $c->param($name_col), $c->param('epr_id')
        );
      } else {
        $c->db->dbh->do(
          "INSERT INTO $table ($name_col) VALUES (?)", undef, $c->param($name_col)
        );
      }
    });
  });
  $r->post("$path/:id")->to(cb => sub ($c) {
    return _admin_error($c, $path, 'Name is required')
      unless defined $c->param($name_col) && $c->param($name_col) ne '';
    return _admin_error($c, $path, 'Period is required')
      if $with_period && (($c->param('epr_id') // '') !~ /^\d+$/);
    _admin_write($c, $path, ucfirst($singular) . ' updated', sub {
      if ($with_period) {
        $c->db->dbh->do(
          "UPDATE $table SET $name_col=?, epr_id=? WHERE $id_col=?",
          undef, $c->param($name_col), $c->param('epr_id'), $c->param('id')
        );
      } else {
        $c->db->dbh->do(
          "UPDATE $table SET $name_col=? WHERE $id_col=?",
          undef, $c->param($name_col), $c->param('id')
        );
      }
    });
  });
  $r->post("$path/:id/delete")->to(cb => sub ($c) {
    _admin_write($c, $path, ucfirst($singular) . ' deleted', sub {
      $c->db->dbh->do("DELETE FROM $table WHERE $id_col=?", undef, $c->param('id'));
    });
  });
}

sub _pagination ($c, $total) {
  my $per_page = 20;
  my $total_pages = int(($total + $per_page - 1) / $per_page) || 1;
  my $page = $c->param('page') // 1;
  $page = 1 unless $page =~ /^\d+$/ && $page > 0;
  $page = $total_pages if $page > $total_pages;
  my $offset = ($page - 1) * $per_page;
  return {
    page => $page,
    per_page => $per_page,
    total => $total,
    total_pages => $total_pages,
    offset => $offset,
    first => $total ? $offset + 1 : 0,
    last => $total < $offset + $per_page ? $total : $offset + $per_page,
  };
}

sub _event_form_data ($c) {
  $c->stash(
    types => $c->db->dbh->selectall_arrayref(
      'SELECT etp_id, etp_name FROM event_types ORDER BY etp_name', {Slice => {}}
    ),
    places => $c->db->dbh->selectall_arrayref(
      'SELECT epl_id, epl_name FROM event_places ORDER BY epl_name', {Slice => {}}
    ),
    periods => $c->db->dbh->selectall_arrayref(
      'SELECT epr_id, epr_name FROM event_periods ORDER BY epr_name', {Slice => {}}
    )
  );
}

sub _admin_write ($c, $path, $success, $operation) {
  if (eval { $operation->(); 1 }) {
    $c->flash(success => $success);
  } else {
    my $error = "$@";
    my $message = $error =~ /FOREIGN KEY constraint failed/
      ? 'This record is in use and cannot be deleted'
      : $error =~ /UNIQUE constraint failed/
        ? 'That record already exists'
        : 'The database operation failed';
    $c->app->log->error($error);
    $c->flash(error => $message);
  }
  $c->redirect_to($path);
  return;
}
sub _admin_error ($c, $path, $message) {
  $c->flash(error => $message);
  $c->redirect_to($path);
  return;
}


1;
