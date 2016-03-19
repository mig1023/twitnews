package TwitNews::Controller::Reg;
use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use DBI;
use File::Copy;
use File::Spec;

my $dbh;
my $sbh;
my $cbh;
my $capcha = {};

## форма регистрации
sub index {
	my ($dir, $code) = capcha();
	$capcha->{$dir} = $code; 
	
	my $self = shift;
	$self->render(capch_code => $dir);
	}

## сама регистрация
sub done {
	my $self = shift;
	my $fail = '';
	
	connect_dbi();
	
	## проверка занятости логина
	my $hashref = $dbh->selectrow_hashref("SELECT * FROM user_name WHERE user_name = ?", {}, $self->param('login'));

	## в любом случае удаляем картинки капчи
	if (length($self->param('p_capcha')) == 16) {
		my $path = (File::Spec->splitpath( __FILE__ ))[1];
		$path =~ s/\/lib\/.*/\//gi;
		unlink $path.'public/capcha/'.$self->param('p_capcha').'/'.$_.'.jpg' for ('A','B','C','D','E','F');
		rmdir $path.'public/capcha/'.$self->param('p_capcha').'/'; }

	## проверка неправильного заполнения регистрационной формы
	$fail = 'неправильно введена капча ' if $self->param('s_capcha') != $capcha->{$self->param('p_capcha')};
	$fail = 'логин уже занят' if $self->param('login') eq $hashref->{'user_name'};
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
				
				## сохранение данных пользователя
				$dbh->do("INSERT INTO user_name(user_name, password, email) VALUES (?,?,?)", {},
						$self->param('login'), md5_str( $self->param('password1')), 
						$self->param('email'));
				
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
	my @symbol = ('A','B','C','D','E','F','a','b','c','d','e','f');
	my $path = (File::Spec->splitpath( __FILE__ ))[1];
	$path =~ s/\/lib\/.*/\//gi;
	my $capcha = 0;

	my $capch_dir;
	do {
	$capch_dir = '';
	$capch_dir .= $symbol[int(rand(11))] for (1..16);
	} while (-e $path.'public/capcha/'.$capch_dir.'/');
	
	mkdir $path.'public/capcha/'.$capch_dir.'/';
	
	for (0..5) { 
		my $number = int(rand(11))+1;
		if (int(rand(2)) == 1) 	{ $number = 'A' . $number;
					  $capcha++; }
			else		{ $number = 'B' . $number; }
		copy( $path.'public/capcha/'.$number.'.jpg' , $path.'public/capcha/'.$capch_dir.'/'.$symbol[$_].'.jpg');
		}; 
	return $capch_dir, $capcha;
	}

## подключение к БД
sub connect_dbi {
	$dbh = DBI->connect("dbi:mysql:dbname=twit_news", $TwitNews::dblog, $TwitNews::dbpwd) or die;
	}

1;
