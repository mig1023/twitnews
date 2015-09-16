package TwitNews::Controller::Add;
use Mojo::Base 'Mojolicious::Controller';
use DBI;

my $dbh;
my $sbh;

## форма добавления новости
sub index {
	my $self = shift;
	$self->render() unless $::login == 0;
	}

## само добавление
sub done {
	my $self = shift;
	my $fail = '';
	
	# проверка превышения допустимых размеров новости и отсутствия пруфа
	$fail = 'слишком длинный заголовок' if length($self->param('head')) > 100;
	$fail = 'слишком длинная новость' if length($self->param('textnews')) > 1000;
	$fail = 'неправильная ссылка на первоисточник'
		if !($self->param('proof') =~ /^(https?:\/\/)([\w\.]+)\.([a-z]{2,6}\.?)(\/[\w\.]*)*\/?$/);
	$fail = 'только зарегистрированные пользователи могут размещать новости' if $::login == 0;;
	
	if ($fail ne '') { 	$self->render(t_xt => "ошибка: $fail!", l_nk => '/add' ); }
	
		else  	 {	connect_dbi(); 
				my $tags_l = $self->param('tags');
				# теги всегда маленькими буквами
				$tags_l =~ tr/[АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ]/[абвгдеёжзийклмнопрстуфхцчшщъыьэюя]/;
				$tags_l =~ tr/[ABCDEFGHIJKLMNOPQRSTUVWXYZ]/[abcdefghijklmnopqrstuvwxyz]/;
				$dbh->do( "INSERT INTO news VALUES ('0','" .
					$::login . "','" .
					$self->param('head') . "','" . 
					$self->param('textnews') . "','" . 
					$self->param('proof') . "','" .
					$tags_l . "','" .
					time . "')" );
				
				$dbh->disconnect();
				
				$self->render(t_xt => "новость успешно размещена!", l_nk => '/');
				}
		}

## подключение к БД
sub connect_dbi {
	$dbh = DBI->connect("dbi:mysql:dbname=twit_news", $TwitNews::dblog, $TwitNews::dbpwd) or die;
	}
	
1;
