package TwitNews::Controller::Index;
use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use DBI;
use Encode qw(decode encode);

my $dbh;
my $sbh;
my $cbh;
my $tag_search = '';
my $comment_id = 0;

## главная страница
sub index {
	my $self = shift;
	my $page_num = $self->stash('page');
	
	my $news = '';
	my $hashref;
	my $tagsref;
	my $commref;
	my %tags = ();
	my $tags = '';
	
	connect_dbi();

	## получение статистики	
	my $news_num = get_stat('news');
	my $user_num = get_stat('user_name');
	my $comm_num = get_stat('comment');
	
	## сортировка и вывод тегов
	$cbh = $dbh->prepare("SELECT tags FROM news;");
	$cbh->execute or die;
	while($tagsref = $cbh->fetchrow_hashref()) {
		my @tags =  split /,/, $tagsref->{'tags'};
		for (@tags) {
			$_ = decode('utf8',$_);
			s/(^\s+|\s+$)//;
			$tags{$_}++;
			};
		};
	
	$tags = join ', ', map {'<a href="/tag/' . $_ . '">' . $_ . '</a>'} sort {$tags{$b} <=> $tags{$a} } keys %tags;
	$tags =~ s/,\s$//;
	
	## вывод новостей: всех или по тегу
	my $tag_search_req = '';
	$tag_search_req = "WHERE tags like '" . $tag_search . "' " if $tag_search ne '';
	
	$sbh = $dbh->prepare("SELECT * FROM news " . $tag_search_req . " order by data desc LIMIT " . ($page_num*10) . ",10;");
	$sbh->execute or die;
	
	## вывод
	while ($hashref = $sbh->fetchrow_hashref()) {
		my $comm_num = 0;
	
		$cbh = $dbh->prepare("SELECT * FROM comment WHERE news_num = " . $hashref->{'num'} . ";");
		$cbh->execute or die;
		$comm_num++ while $commref = $cbh->fetchrow_hashref();

		$news .='<font class = head_font>' .		decode('utf8', $hashref->{'head'}) . 
			'</font><br><font class = news_font>' .	decode('utf8', $hashref->{'news'}) . 
			'</font><br><font class = sub_font>' .	decode('utf8', $hashref->{'user_name'}) .
			' | ' .					timeformat($hashref->{'data'}) .
			' | <a href="/news/' . 			$hashref->{'num'} .
			'/">' . 				$comm_num .
			' коммент.</a> | <a href="' . 		decode('utf8', $hashref->{'link'}) .
			'">' .					decode('utf8', $hashref->{'link'}) .
			'</a></font>' . '<br>'x3;
		}
	
	$sbh->finish();
	$dbh->disconnect();
	$self->render(  login => $::login,
			newst => $news,
			tagst => $tags,
			tagse => $tag_search,
			num_p => $page_num,
			newsn => $news_num,
			usern => $user_num,
			commn => $comm_num );
	}

## залогинивание
sub login {
	my $self = shift;
	
	connect_dbi();
	
	## получение данных по логину
	$sbh = $dbh->prepare("SELECT * FROM user_name WHERE user_name = '" . $self->param('login') . "';");
	$sbh->execute or die;
	my $hashref = $sbh->fetchrow_hashref();
	$sbh->finish();
	$dbh->disconnect();
	
	## проверка пароля
	if ( $hashref->{'password'} eq md5_str($self->param('pass')) ) {
		$::login = $self->param('login');
		$self->redirect_to('/'); }
	else {
		$::login = 0;
		$self->render(); };
	}

## разлогинивание
sub logout {
	my $self = shift;
	$::login = 0;
	
	$self->redirect_to('/');
	}

## отдельная новость с комментариями
sub comm {
	my $self = shift;
	$comment_id = $self->stash('id');
	my $news = '';
	my $comm = '';
	my $commref;
	
	connect_dbi();
	
	## сама новость
	$sbh = $dbh->prepare("SELECT * FROM news WHERE num = " . $comment_id . ";");
	$sbh->execute or die;
	
	my $hashref = $sbh->fetchrow_hashref();
	
	$news .= '<font class = head_font>' .		decode('utf8', $hashref->{'head'}) . 
		'</font><br><font class = news_font>' .	decode('utf8', $hashref->{'news'}) . 
		'</font><br><font class = sub_font>' .	decode('utf8', $hashref->{'user_name'}) .
		' | ' .					timeformat($hashref->{'data'}) .
		' | <a href="' . 			decode('utf8', $hashref->{'link'}) . 
		'">' .					decode('utf8', $hashref->{'link'}) .
		'</a></font>' . '<br>'x3;
	
	## комментарии 
	$cbh = $dbh->prepare("SELECT * FROM comment WHERE news_num = " . $comment_id . " order by data;");
	$cbh->execute or die "\nerror query!";
	while($commref = $cbh->fetchrow_hashref()) { 
		$comm .= '<font class = news_font>' .	decode('utf8', $commref->{'comment'}) . 
		'</font><br><font class = sub_font>' . 	decode('utf8', $commref->{'user_name'}) . 
		' | ' .					timeformat($commref->{'data'}) .
		'</font>' . '<br>'x2; };
	
	$sbh->finish();
	$dbh->disconnect();
	$self->render(  login => $::login,
			newst => $news,
			commt => $comm );
	}

## добавление нового комментария
sub newcomm {
	my $self = shift;
	
	connect_dbi();
	
	$dbh->do("INSERT INTO comment VALUES ('0','" .
		$comment_id . "','" .
		$::login . "','" . 
		$self->param('textcomm') . "','" . 
		time . "')" );

	$dbh->disconnect();
	
	$self->render(t_xt => 'комментарий сохранён!', l_nk => '/');
	}

## отбор новостей по тегу
sub tag {
	my $self = shift;
	$tag_search = $self->stash('tag');
	$self->redirect_to('/');
	}

## возврат ко всем новостям
sub tag_out {
	my $self = shift;
	$tag_search = '';
	$self->redirect_to('/');
	}

## расчёт md5 для строки
sub md5_str {
	my $md5 = Digest::MD5->new->add(shift);
	$md5->hexdigest;
	}

## читабельный формат даты
sub timeformat {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(shift);
	$year += 1900;
	my $str = $mday . '.' . $mon . '.' . $year . ' ' . $hour . ':' . $min;
	$str;
	}

## получение статистики
sub get_stat { 
	my $hashref;
	my $number;
	
	$cbh = $dbh->prepare('SELECT COUNT(1) as num FROM ' . shift .';');
	$cbh->execute or die;
	$hashref = $cbh->fetchrow_hashref();
	$number = $hashref->{'num'};
	$number;
	}

## подключение к БД
sub connect_dbi {
	$dbh = DBI->connect("dbi:mysql:dbname=twit_news", $TwitNews::dblog, $TwitNews::dbpwd) or die;
	}

1;
