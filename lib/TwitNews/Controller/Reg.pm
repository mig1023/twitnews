package TwitNews::Controller::Reg;
use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use DBI;
use File::Copy;
use File::Spec;
use DB_connect_info;

my $dbh;
my $sbh;
my $cbh;
my $capcha = 0;

## форма регистрации
sub index {
	capcha();
	
	my $self = shift;
	$self->render();
	}

## сама регистрация
sub done {
	my $self = shift;
	my $fail = '';
	
	connect_dbi();
	
	$cbh = $dbh->prepare("SELECT * FROM user_name WHERE user_name = '" . $self->param('login') . "';");
	$cbh->execute or die;
	my $hashref = $cbh->fetchrow_hashref();

	$fail = 'неправильно введена капча' if $self->param('s_capcha') != $capcha;
	$fail = 'логин уже занят' if $self->param('login') eq $hashref->{'user_name'};
	$fail = 'неправильная каптча' if $self->param('s_capcha') != $capcha;
	$fail = 'пароли не совпадают' if $self->param('password1') ne $self->param('password2');
	$fail = 'неправильный email' if !($self->param('email') =~ /.+@.+\..+/i);
	$fail = 'не введена капча' if $self->param('s_capcha') eq '';
	$fail = 'не задан email' if $self->param('email') eq '';
	$fail = 'не повторён пароль' if $self->param('password2') eq '';
	$fail = 'не задан пароль' if $self->param('password1') eq '';
	$fail = 'не задан логин' if $self->param('login') eq '';
	
	if ($fail ne '') { 	$self->render(t_xt => "ошибка: $fail! ", l_nk => '/reg' );
				$dbh->disconnect(); }
	
		else  	 {	$::login = $self->param('login');
				$dbh->do("INSERT INTO user_name VALUES ('0','" .
					$self->param('login') . "','" .
					md5_str( $self->param('password1')) . "','" . 
					$self->param('email') . "')" );
				$dbh->disconnect();
				
				$self->render(t_xt => 'регистрация прошла успешно!', l_nk => '/');
				}
		}

## расчёт md5 строки	
sub md5_str {
	my $md5 = Digest::MD5->new->add(shift);
	$md5->hexdigest;
	}

## капча (6 случайных картинок)
sub capcha {
	my @symbol = ('A','B','C','D','E','F');
	my $path = (File::Spec->splitpath( __FILE__ ))[1];
	$path =~ s/\/lib\/.*/\//gi;
	$capcha = 0;
	for (0..5) { 
		my $number = int(rand(11))+1;
		if (int(rand(2)) == 1) 	{ $number = 'A' . $number;
					  $capcha++; }
			else		{ $number = 'B' . $number; }
		copy( $path.'public/capcha/'.$number.'.jpg' , $path.'public/capcha/'.$symbol[$_].'.jpg');
		}; 
	}

## подключение к БД
sub connect_dbi {
	$dbh = DBI->connect("dbi:mysql:dbname=twit_news", &db_login, &db_pwd) or die;
	}

1;
