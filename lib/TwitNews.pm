package TwitNews;
use Mojo::Base 'Mojolicious';

our $login = 0;

sub startup {
  my $self = shift;
  my $r = $self->routes;
  
  ## главная
  $r->any('/')->to('index#index');

  ## вход в личный кабинет
  $r->any('/login')->to('index#login');
  
  ## выход из него
  $r->any('/logout')->to('index#logout');
  
  ## отдельная новость с комментариями
  $r->any('/news/:id/')->to('index#comm', id => 1);
  
  ## добавить комментарий
  $r->any('/add_comm')->to('index#newcomm');
  
  ## отбор новостей по тегу
  $r->any('/tag/:tag/')->to('index#tag', tag => 1);
  
  ## возвращение ко всем новостям
  $r->any('/tag_out')->to('index#tag_out');
  
  ## форма регистрации
  $r->any('/reg')->to('reg#index');
  
  ## сама регистрация
  $r->any('/reg_done')->to('reg#done');
  
  ## форма добавление новости
  $r->any('/add')->to('add#index');
  
  ## её добавление
  $r->any('/add_done')->to('add#done');
  
}

1;
