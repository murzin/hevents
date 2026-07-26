use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use File::Temp qw(tempdir);
use DBI;
use FindBin qw($Bin);
use File::Spec;

my $tmp = tempdir(CLEANUP => 1);
$ENV{HEVENTS_DB} = File::Spec->catfile($tmp, 'test.db');
my $root = File::Spec->catdir($Bin, '..');
my $schema_file = File::Spec->catfile($root, '..', 'DDL', 'ddl.sql');

open my $fh, '<:encoding(UTF-8)', $schema_file or die $!;
local $/;
my $schema = <$fh>;
close $fh;

my $dbh = DBI->connect(
  "dbi:SQLite:dbname=$ENV{HEVENTS_DB}", '', '',
  {RaiseError => 1, PrintError => 0}
);
$dbh->do($_) for grep { /\S/ } split /;/, $schema;
my %event_indexes = map { $_->{name} => 1 }
  @{$dbh->selectall_arrayref('PRAGMA index_list(events)', {Slice => {}})};
my %link_indexes = map { $_->{name} => 1 }
  @{$dbh->selectall_arrayref('PRAGMA index_list(event_links)', {Slice => {}})};
ok($event_indexes{events_evt_id_idx}, 'events has an explicit evt_id index');
ok($link_indexes{event_links_evt_ids_idx}, 'event_links has a composite ID index');
ok(!$link_indexes{event_links_evt_id_2_idx}, 'event_links reverse lookup index is absent');
$dbh->disconnect;

use lib "$Bin/../lib";
require EventsApp;
my $t = Test::Mojo->new(EventsApp->new);
$t->get_ok('/health')->status_is(200)->json_is('/status' => 'ok');
$t->get_ok('/')->status_is(200)->content_like(qr/People and Events/);
$t->get_ok('/api/event_types')->status_is(200)->json_is([]);

$t->post_ok('/event_types' => json => {etp_name => 'Conference'})
  ->status_is(201)->json_is('/id' => 1);
$t->post_ok('/event_places' => json => {epl_name => 'Tbilisi'})
  ->status_is(201)->json_is('/id' => 1);
$t->post_ok('/event_periods' => json => {epr_name => 'Evening'})
  ->status_is(201)->json_is('/id' => 1);
$t->get_ok('/event_types/1')->status_is(200)
  ->json_is('/etp_name' => 'Conference');
$t->get_ok('/event_places/999')->status_is(200)->json_is({});
$t->get_ok('/event_periods')->status_is(200)
  ->json_is('/0/epr_name' => 'Evening');
$t->get_ok('/event_periods/1')->status_is(200)
  ->json_is('/epr_id' => 1);
$t->put_ok('/event_periods/1' => json => {epr_name => 'Late evening'})
  ->status_is(200)->json_is('/success' => 1);
$t->get_ok('/event_periods/1')->json_is('/epr_name' => 'Late evening');
$t->get_ok('/admin')->status_is(200)->content_like(qr/Historical events, clearly managed/);
$t->get_ok('/admin.css')->status_is(200)->content_like(qr/--forest/);
$t->get_ok('/admin/event_types')->status_is(200)->content_like(qr/Event types/);
$t->post_ok('/admin/event_types' => form => {etp_name => 'Exhibition'})
  ->status_is(302);
$t->get_ok('/admin/event_types')->content_like(qr/Exhibition/);
$t->post_ok('/admin/event_types/2' => form => {etp_name => 'Museum exhibition'})
  ->status_is(302);
$t->get_ok('/admin/event_types')->content_like(qr/Museum exhibition/);
$t->post_ok('/admin/event_types/2/delete')->status_is(302);
$t->app->db->do('INSERT INTO event_types (etp_name) VALUES (?)', undef, "Bulk type $_")
  for 1 .. 21;
$t->get_ok('/admin/event_types?page=1')->status_is(200)
  ->content_like(qr/Showing 1.+20 of 22/s)
  ->content_unlike(qr/Bulk type 21/);
$t->get_ok('/admin/event_types?page=2')->status_is(200)
  ->content_like(qr/Page 2 of 2/)
  ->content_like(qr/Bulk type 21/);
$t->get_ok('/admin/event_types?page=999')->status_is(200)
  ->content_like(qr/Page 2 of 2/);

my $event = {
  evt_name => 'Perl Meetup',
  evt_desc => 'A Perl community event',
  evt_url  => 'https://example.test/events/1',
  evt_from => '2026-08-01T18:00:00Z',
  evt_to   => '2026-08-01T20:00:00Z',
  etp_id   => 1,
  epl_id   => 1,
  epr_id   => 1,
};
$t->post_ok('/events' => json => $event)->status_is(201)->json_is('/id' => 1);
$t->post_ok('/events' => json => {%$event, evt_name => 'Second Event'})
  ->status_is(201)->json_is('/id' => 2);
$t->post_ok('/events' => json => {
  %$event,
  evt_name => 'Historical year format',
  evt_from => '980',
  evt_to   => '1037',
})->status_is(201)->json_is('/id' => 3);
$t->get_ok('/admin/events')->status_is(200)->content_like(qr/Perl Meetup/);
$t->get_ok('/admin/events/1/edit')->status_is(200)->content_like(qr/Edit event/);
$t->get_ok('/admin/events/new')->status_is(200)->content_like(qr/New event/);
$t->post_ok('/admin/events' => form => {
  %$event,
  evt_name => 'Admin-created event',
})->status_is(302);
$t->get_ok('/admin/events')->content_like(qr/Admin-created event/);
$t->post_ok('/admin/events/4' => form => {
  %$event,
  evt_name => 'Admin-updated event',
})->status_is(302);
$t->get_ok('/admin/events')->content_like(qr/Admin-updated event/);
$t->get_ok('/admin/events?q=perl')->status_is(200)
  ->content_like(qr/Perl Meetup/)
  ->content_unlike(qr/Admin-updated event/);
$t->get_ok('/admin/events?q=admin-updated&etp_id=1&epl_id=1&epr_id=1')
  ->status_is(200)
  ->content_like(qr/Admin-updated event/)
  ->content_like(qr/value="admin-updated"/);
$t->get_ok('/admin/events?etp_id=999')->status_is(200)
  ->content_like(qr/No events match these filters/);
$t->app->db->do(q{
  INSERT INTO events
    (evt_name, evt_desc, evt_url, evt_from, evt_to, etp_id, epl_id, epr_id)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
}, undef, "Paged event $_", 'Pagination fixture', 'https://example.test/paged',
  '1900', '1901', 1, 1, 1) for 1 .. 21;
$t->get_ok('/admin/events?q=Paged%20event&page=1')->status_is(200)
  ->content_like(qr/Showing 1.+20 of 21/s)
  ->content_unlike(qr/Paged event 21/);
$t->get_ok('/admin/events?q=Paged%20event&page=2')->status_is(200)
  ->content_like(qr/Paged event 21/)
  ->content_like(qr/Page 2 of 2/);
$t->app->db->do("DELETE FROM events WHERE evt_name LIKE 'Paged event %'");
$t->get_ok('/events')->status_is(200)
  ->json_is('/0/evt_name' => 'Perl Meetup')
  ->json_is('/0/etp_name' => 'Conference')
  ->json_is('/0/epl_name' => 'Tbilisi');
  $t->get_ok('/events/1')->json_is('/epr_name' => 'Late evening');
$t->get_ok('/events/1')->status_is(200)->json_is('/evt_id' => 1);
$t->put_ok('/events/1' => json => {%$event, evt_desc => 'Updated'})
  ->status_is(200)->json_is('/success' => 1);
$t->get_ok('/events/1')->json_is('/evt_desc' => 'Updated');

$t->post_ok('/event_links' => json => {evt_id_1 => 2, evt_id_2 => 1})
  ->status_is(201)->json_is('/success' => 1);
$t->get_ok('/admin/event-links')->status_is(200)->content_like(qr/Perl Meetup/);
$t->get_ok('/event_links/1')->status_is(200)
  ->json_is('/0/evt_id' => 2);
$t->delete_ok('/event_links' => json => {evt_id_1 => 1, evt_id_2 => 2})
  ->status_is(200)->json_is('/success' => 1);

$t->post_ok('/events' => json => {evt_name => 'Incomplete'})
  ->status_is(422)->json_is('/error' => 'Missing required fields');
$t->post_ok('/event_links' => json => {evt_id_1 => 1, evt_id_2 => 1})
  ->status_is(422);

$t->delete_ok('/events/1')->status_is(200)->json_is('/success' => 1);
$t->get_ok('/events/1')->status_is(200)->json_is({});
$t->delete_ok('/events/2')->status_is(200);
$t->delete_ok('/events/3')->status_is(200);
$t->post_ok('/admin/events/4/delete')->status_is(302);
$t->delete_ok('/event_types/1')->status_is(200);
$t->delete_ok('/event_places/1')->status_is(200);
$t->delete_ok('/event_periods/1')->status_is(200);

done_testing;
