package TwitNews;
use Mojo::Base 'Mojolicious';

our $login = 0;

sub startup {
  my $self = shift;
  my $r = $self->routes;
  
  $r->any('/')->to('index#index');

  $r->any('/login')->to('index#login');
  
  $r->any('/logout')->to('index#logout');
  
  $r->any('/news/:id/')->to('index#comm', id => 1);
  
  $r->any('/add_comm')->to('index#newcomm');
  
  $r->any('/tag/:tag/')->to('index#tag', tag => 1);
  
  $r->any('/tag_out')->to('index#tag_out');
  
  $r->any('/reg')->to('reg#index');
  
  $r->any('/reg_done')->to('reg#done');
  
  $r->any('/add')->to('add#index');
  
  $r->any('/add_done')->to('add#done');
  
}

1;
