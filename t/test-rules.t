#!perl -w
use URI::Find::Rule;
use Data::Dumper;
use Test::More tests => 41;

my $png = 'http://ipy.frottage.org/rjp/2003/09/07/definitely.png';
my $cgi = 'http://ipy.frottage.org/cgi-bin/rjp/env.cgi?query=frottage';
my $fragment = 'http://ipy.frottage.org/rjp/#page1';
my $ldap = 'ldap://server/o=frottage.org?uid?sub?(uid=%s)';
my $news = 'news://news.easynet.co.uk/slrnbnntv2.1n95.rjp@ipy.frottage.org';
my $nntp = 'nntp:slrnbnntv2.1n95.rjp@ipy.frottage.org';
my $auth = 'http://rjp:badgers@ty.pi.st/secret/stash/';
my $ssl = 'https://hotmail.com/';

my $text = <<TEST_TEXT;
this is some text with embedded links to people I know, http://plig.net/,
places I run, http://frottage.org/, helpful ftp sites, ftp://ftp.plig.org/,
a png that helps people to spell, $png, a cgi, $cgi, a page fragment, 
$fragment, and some miscellaneous other URLS -- $ldap, $news, $nntp, 
$auth, $ssl.
TEST_TEXT

my @a = URI::Find::Rule->scheme('http')->in($text);
is(scalar @a, 6);
ok( URI::eq($a[0]->[1], 'http://plig.net/') , 'uri');
ok( URI::eq($a[1]->[1], 'http://frottage.org/') , 'uri');
ok( URI::eq($a[2]->[1], $png) , 'uri');
ok( URI::eq($a[3]->[1], $cgi) , 'uri');
ok( URI::eq($a[4]->[1], $fragment) , 'uri');
ok( URI::eq($a[5]->[1], $auth) , 'uri');

my @http = URI::Find::Rule->http()->in($text);
is_deeply(\@a, \@http, 'found all @http in $text');

@a = URI::Find::Rule->host(qr/plig/)->in($text);
is(scalar @a, 2, '2 plig uris');

ok( URI::eq($a[0]->[1], 'http://plig.net/'), 'uri' );
ok( URI::eq($a[1]->[1], 'ftp://ftp.plig.org/') , 'uri');

@a = URI::Find::Rule->path(qr/rjp/)->in($text);
is(scalar @a, 5, '5 rjp uris');
ok( URI::eq($a[0]->[1], $png) );
ok( URI::eq($a[1]->[1], $cgi) );
ok( URI::eq($a[2]->[1], $fragment) );
ok( URI::eq($a[3]->[1], $news) );
ok( URI::eq($a[4]->[1], $nntp) );

@a = URI::Find::Rule->fragment(qr/./)->in($text);
is(scalar @a, 1);
ok( URI::eq($a[0]->[1], $fragment) );

@a = URI::Find::Rule->host(qr/plig/)->scheme('http')->in($text);
is(scalar @a, 1, 'host: /plig/, scheme: http, 1 match');
ok( URI::eq($a[0]->[1], 'http://plig.net/') );

my @b = URI::Find::Rule->http(qr/plig/)->in($text);
is(scalar @b, 1, 'http: /plig/, 1 match');
is_deeply(\@a, \@b);

@a = URI::Find::Rule->scheme('http')->host(qr/plig/, qr/frottage/)->in($text);
is(scalar @a, 5, 'scheme: http, host: /plig/ or /frottage/, 5 matches');

my @c = URI::Find::Rule->http(qr/plig/, qr/frottage/)->in($text);
is(scalar @c, 5, 'http: plig or frottage, 5 matches');
is_deeply(\@a, \@c);

@a = URI::Find::Rule->host('*plig*')->scheme('http')->in($text);
is(scalar @a, 1);
ok( URI::eq($a[0]->[1], 'http://plig.net/') );

@a = URI::Find::Rule->host('news.easynet.co.uk')->in($text);
is(scalar @a, 1);
is($a[0]->[1], $news);

@a = URI::Find::Rule->in($text);
is(scalar @a, 11);

@a = URI::Find::Rule->host(qr/plig/, qr/frottage/)->in($text);
is(scalar @a, 6);

@a = URI::Find::Rule->ftp(qr/plig/, qr/frottage/)->in($text);
is(scalar @a, 1);

@a = URI::Find::Rule->authority(qr/rjp/)->in($text);
is(scalar @a, 1);

@a = URI::Find::Rule->query(qr/./)->in($text);
is(scalar @a, 2);
ok( URI::eq($a[0]->[1], $cgi) );
# ok( URI::eq($a[1]->[1], $ldap) ); # this fails because URI::Find munges the LDAP uri

# port 80 is the default for HTTP, so this is equivalent to ->scheme('http')
@a = URI::Find::Rule->port(80)->in($text);
is_deeply(\@a, \@http);

@a = URI::Find::Rule->port(443)->in($text);
is(scalar @a, 1);
ok( URI::eq($a[0]->[1], $ssl) );

@a = URI::Find::Rule->userinfo(qr/rjp/)->in($text);
is(scalar @a, 1);
ok( URI::eq($a[0]->[1], $auth) );
