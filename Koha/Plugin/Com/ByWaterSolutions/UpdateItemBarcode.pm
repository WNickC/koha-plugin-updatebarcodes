package Koha::Plugin::Com::ByWaterSolutions::UpdateItemBarcode;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

## We will also need to include any Koha libraries we want to access
use C4::Context;
use C4::Auth;

## Here we set our plugin version
our $VERSION = 1.01;

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'Update barcode',
    author          => 'Nick Clemens',
    description     => 'Quickly change an items barcode in Koha.',
    date_authored   => '2015-02-14',
    date_updated    => '2015-02-14',
    minimum_version => '3.1000000',
    maximum_version => undef,
    version         => $VERSION,
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $next_step = $cgi->param('next_step');

    if ( $next_step eq '2' ) {
        $self->step2();
    } elsif ( $next_step eq '3' ) {
        $self->step3();
    } else {
        $self->step1();
    }
}

## These are helper functions that are specific to this plugin
## You can manage the control flow of your plugin any
## way you wish, but I find this is a good approach
sub step1 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $template = $self->get_template( { file => 'step1.tt' } );

    print $cgi->header();
    print $template->output();
}

sub step2 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;

    my $barcode = $cgi->param("barcode");

    my $query = "
        SELECT * 
        FROM items
        LEFT JOIN biblio USING (biblionumber)
        WHERE barcode = ?
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute($barcode);
    my $record = $sth->fetchrow_hashref();

    my $template = $self->get_template( { file => "step2.tt" } );

    $template->param( record => $record );

    print $cgi->header();
    print $template->output();
}

sub step3 {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    my $dbh = C4::Context->dbh;
	
    my $barcode = $cgi->param("barcode");
    my $new_barcode = $cgi->param("new_barcode");

    my $r = $dbh->do( 'UPDATE items SET barcode = ? WHERE barcode = ?;', undef,$new_barcode, $barcode );

    my $template = $self->get_template( { file => "step3.tt" } );
    $template->param( record_deleted => $r );
    $template->param( change_made => $barcode."->".$new_barcode);

    print $cgi->header();
    print $template->output();
}

1;
