package TwitNews::Controller::Add;
use Mojo::Base 'Mojolicious::Controller';
use DBI;

my $dbh;
my $sbh;

sub index {
	my $self = shift;
	$self->render();
	}

sub done {
	my $self = shift;
	my $fail = '';
	
	$fail = 'слишком длинный заголовок' if length($self->param('head')) > 100;
	$fail = 'слишком длинная новость' if length($self->param('textnews')) > 1000;
	$fail = 'неправильная ссылка на первоисточник'
		if !($self->param('proof') =~ /^(https?:\/\/)([\w\.]+)\.([a-z]{2,6}\.?)(\/[\w\.]*)*\/?$/);
	
	if ($fail ne '') { 	$self->render(t_xt => "ошибка: $fail!", l_nk => '/add' ); }
	
		else  	 {	connect_dbi();
				$dbh->do( "INSERT INTO news VALUES ('0','" .
					$::login . "','" .
					$self->param('head') . "','" . 
					$self->param('textnews') . "','" . 
					$self->param('proof') . "','" .
					$self->param('tags') . "','" .
					time . "')" );
				$dbh->disconnect();
				
				$self->render(t_xt => "новость успешно размещена!", l_nk => '/');
				}
		}

sub connect_dbi {
	$dbh = DBI->connect("dbi:mysql:dbname=twit_news", "login", "password") or die;
	}

1;
