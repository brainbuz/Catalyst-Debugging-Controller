package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 VERSION 1.03

=head1 DESCRIPTION

This is a small application useful for configuration testing.
It can tell you what time it is.
The useful thing it does is dump out lots of 
information about your environment.

=head1 METHODS

=head2 index

The root page (/) This is the Catalyst Default root page. Your application is 
able to produce output.

=head2 brief

Will tell you who is logged in and what time it is.

=head2 spew

Dumps a whole bunch of stuff out of your environment. 
Like pages of it. 

=head2 form

If you point a form at this page instead of spew, it will only tell you
the GET and POST parameters. spew already includes the form data dump, use
it to get everything.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

my $spit = sub {
    my $ref = shift ;
    my $desc = shift ;
    my $spewage = "\n<b>$desc</b>\n" ;
    my %params = %{ $ref } ;
        foreach my $k ( keys %params )     {
            $spewage .= " * $k = $params{ $k }\n" ; } ;  
    return $spewage ;
    } ;

my $form = sub {
    my $req = shift ; 
    my $reply = '' ;
    if ( keys ( %{$req->{body_parameters}} ) ) {
    $reply .= $spit->( $req->{body_parameters} , 'Body Parameters (POST)' ) ;
    } else { $reply .= "\n<b>Body Parameters (POST)</b> is empty. \n This means there is " .
        "No POST DATA.\n Point a form here to debug it.\n" }
    if ( keys ( %{$req->{query_parameters}} ) ) {
    $reply .= $spit->( $req->{query_parameters} , 'Query Parameters (GET)' ) ;
    } else { $reply .= "\n<b>Query Parameters (GET)</b> is empty. \n This means there is " .
        "No GET DATA.\n Point a form here to debug it.\n" }    
    return $reply ;
    } ;   
        
sub brief :Path( 'brief' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $t = localtime ;
    my $digestname = 
        $c->engine->env->{'HTTP_AUTHORIZATION'} ||
        "Sorry server didn\'t return this value. Noone is logged in now." ;
    my $cookie = $c->engine->env->{'HTTP_COOKIE'} ||
	"Cookie not set" ;
    my ($username) = $digestname =~ m/username="(.*)", realm/ ;
    if ( $username ) { $username =   
        "The Captured User Name: $username" }
    my $briefwords = qq /
    <pre>
    It is $t 
    The string Apache sends back when a user is logged in
    via digest authentication is:
    \$c->engine->env->{'HTTP_AUTHORIZATION'} = $digestname  
    $username 
    If you're using Apache 2.4 mod_auth_form or session modules
    you might want this string.
    \$c->engine->env->{'HTTP_COOKIE'} = $cookie
     <\/pre>/;
    $c->response->body( $briefwords );
}

sub spew :Path( 'spew' ) :Args() {
    my ( $self, $c ) = @_;

    my $reply = "<html><body><pre>\n<b>Catalyst Controller Dump</b>\n\n";
    if ( $c->config->{using_frontend_proxy} ) {
        $reply .= " <i><u>Using_frontend_proxy is configured in Config File.</i></u>\n" ;
        } else { 
        $reply .= " <i><u>using_frontend_proxy NOT configured in Config File.</i></u>\n" ;
        }
    $reply .= $spit->( $c->config, "Configuration Values" ) ;
    $reply .= $spit->( $c, "All of the keys of your catalyst object" ) ;
    $reply .= $spit->( $c->engine->env, 
        "Plack Environment Values\nc-&gt;engine-&gt;env" ) ;
    if ( defined $c->{cookies} ) {
        $reply .= $spit->( $c->{cookies} , "Cookies" ) }
    else { $reply .= "\n<B>No Cookies were sent by the client.</B>\n" }   
    $reply .= $spit->( $c->request , 'Catalyst::Request' ) ;       
    $reply .= $form->( $c->request ) ;        
    $reply .= "</pre></body></html>" ;
    $c->response->body( $reply );    
}

sub form :Path( 'form' ) :Args(0) {
    my ( $self, $c ) = @_;
    my $reply = "<html><body><pre>\n<B>Form Dump</b>\n" ;
    $reply .= $form->( $c->request ) ;        
    $reply .= "</pre></body></html>" ; 
    $c->response->body( $reply );    
}
    

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

John Karr

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
