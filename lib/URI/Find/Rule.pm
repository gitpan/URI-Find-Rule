package URI::Find::Rule;

use strict;
use vars qw/$VERSION $AUTOLOAD/;
use URI::Find;
use URI;
use Text::Glob 'glob_to_regex';

$VERSION = '0.5';

=head1 NAME

URI::Find::Rule - Simpler interface to URI::Find

=head1 SYNOPSIS

  use URI::Find::Rule;
  # find all the http URIs in some text
  my @uris = URI::Find::Rule->scheme('http')->in($text);
  # or
  my @uris = URI::Find::Rule->http->in($text);

  # find all the URIs referencing a host
  my @uris = URI::Find::Rule->host(qr/myhost/)->in($text);

=head1 DESCRIPTION

URI::Find::Rule is a simpler interface to URI::Find closely
modelled on File::Find::Rule by Richard Clamp.

=cut

sub _force_object {
    my $object = shift;
    $object = $object->new()
      unless ref $object;
    $object;
}

sub _flatten {
    my @flat;
    while (@_) {
        my $item = shift;
        ref $item eq 'ARRAY' ? push @_, @{ $item } : push @flat, $item;
    }
    return @flat;
}

sub in {
    my $self = _force_object shift;
	my @urls;
	my $sub = sub {
		my ($original, $uri) = @_;
        my $uri_object = URI->new($uri);
        my $keep = 1;
        foreach my $i (@{ $self->{rules} }) {
            my $result = &{$i->{code}}($original, $uri, $uri_object);
            $keep = $keep & $result;
        }
        if ($keep) {
            push @urls, [$original, $uri];
        }
		return $original;
	};
	my $finder = URI::Find->new($sub);
	$finder->find(\$_[0]);
	return @urls;
}

sub new {
    my $referent = shift;
    my $class = ref $referent || $referent;
    my $self = bless {
        rules => []
    }, $class;
    return $self;
}

*protocol=\&scheme;

sub AUTOLOAD
{
    (my $method = $AUTOLOAD) =~ s/^.*:://;
	return if $method eq 'DESTROY';


    if (URI->new("http://a/b#c?d")->can($method)) {
        my $code = <<'DEFINE_AUTO';
sub _FUNC_ {
    my $self = _force_object shift;
    my @names = map { ref $_ eq "Regexp" ? $_ : glob_to_regex $_ }  _flatten( @_ );
    my $regex = join( '|', @names );

    push @{ $self->{rules} }, {
        rule => '_FUNC_',
        code => sub { ( $_[2]->_FUNC_() || '' )=~ /$regex/ },
        args => \@_,
    };

    return $self;
}
DEFINE_AUTO
        $code =~ s/_FUNC_/$method/g;
        my $sub = eval $code;
        {
            no strict 'refs';
            return &$AUTOLOAD(@_);
        }
    } else {
        my $code = <<'DEFINE_SCHEME';
sub _FUNC_ {
    my $self = _force_object shift;
    if (@_) {
        $self->scheme('_FUNC_')->host(@_);
    } else {
        $self->scheme('_FUNC_');
    }
}
DEFINE_SCHEME
        $code =~ s/_FUNC_/$method/g;
        eval $code;
        {
            no strict 'refs';
            return &$AUTOLOAD(@_);
        }
    }
}

1;

