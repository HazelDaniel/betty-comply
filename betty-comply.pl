#!/usr/bin/perl
use Term::ANSIColor qw(:constants);
use open qw/:std :utf8/;
use v5;

=for
====== WELCOME TO MY LITTLE PROJECT! ======
  DESCRIPTION : BASIC FILE PROCESSING PROGRAM WRITTEN IN PERL.
=cut

#GLOBALS
$parameters = $#ARGV + 1;
@file_lines = ();
%f_property = ('nu',"numbered-and-upper",'nl',"numbered-and-lower",'n',"numbered",'u',"upper",'l',"lower");
%f_long_property = ('--stop-at='=>"set-stop",'--offset='=>"set-offset");
$REMOVAL_PLACEHOLDER = "BC<reserved>";
#END OF GLOBALS

#SUB-ROUTINES
sub parse_and_chomp {
  my $args = scalar(@_);
  if($args != 1){
	print "Wrong argument in subroutine!";
	exit 271;
  }

  @vecs = @_;
  my $arg1 = $vecs[0];
  my $arg2 = $vecs[1];
  open(MYINPUTFILE, $vecs[0]) or die "can't open: $!";
  while(<MYINPUTFILE>)
  {
	# Good practice to store $_ value
	my($line) = $_;

	chomp($line);
	push(@file_lines,$line);
  }

}


sub write_parsed_lines {
  my ($arg_offset) = @_;
  open(FH, '>', $ARGV[$arg_offset]) or die $!;
  for my $file (@file_lines) {
	if (not grep (/BC<reserved>/,$file)) {
		print FH "$file\n";
	}
	#print FH "$file\n" unless $file =~ /^.*BC<reserved>.*$/;
  }
  close(FH);
  @file_lines = ();
  update_file_lines($arg_offset);
}
sub spaces_to_tabs {
  my ($arg_offset) = @_;
  my $l_count = 0;
  for my $file (@file_lines) {
	if ($file =~ /^( *)([^ ])(.*$)/mg) {
	  $file_lines[$l_count] = $2 . $3;
	}
	$l_count++;
  }
  write_parsed_lines($arg_offset);
}
sub format_trailing {
  my ($arg_offset) = @_;
  my $l_count = 0;
  for my $f_line (@file_lines) {
	if ($f_line =~ /^\s*[[:print:]]+\s*\{\s*$/) {
	  if($f_line =~ /^\s*(do)\s*(\{\s*)$/mg) {
			$f_line = $1 . $2;
			$file_lines[$l_count] = $f_line;
	  }
	  elsif($f_line =~ /^\s*(\})\s*(else)\s*(if\s*\(\s*[[:print:]]+\s*\))?\s*(\{)\s*$/mg) {
			my $new_opening_brace = $1 . "\n";
			my $new_closing_brace = "\n" . $4;
			my $f_line = $new_opening_brace . $2 . " " . $3 . " " . $new_closing_brace;
			$file_lines[$l_count] = $f_line;
			#print "an else if block met \"$f_line\"\n";
	  }
		elsif($f_line =~ /^(\s*)(while|for)\s*(\([[:print:]]+\))\s*(\{)?\s*$/mg) {
			$f_line = $1 . $2 . " " . $3 . "\n$4";
			$file_lines[$l_count] = $f_line;
		}
		#TODO: ADD SUPPORT FOR FOR LOOPS
	  elsif(not grep /^\s*(do)\s*\{\s*$/,$f_line) {
			$f_line =~ s/{$/\n\{/m;
			$file_lines[$l_count] = $f_line;
	  }
	}
	$l_count++;
  }
  write_parsed_lines($arg_offset);
}


sub format_file {
  my ($arg_offset) = @_;
	multi_parse_and_chomp($arg_offset);
  spaces_to_tabs($arg_offset);
  format_trailing($arg_offset);
  adjust_indent($arg_offset);
  rm_trailing_wp($arg_offset);
  separate_RD_tokens($arg_offset);
  remove_blanks($arg_offset);
	cast_entry($arg_offset);
  no_brace_indent($arg_offset);
	format_ctrl_keywords($arg_offset);
	wrap_return($arg_offset);
	unpad_parentheses($arg_offset);
	pad_defs($arg_offset);
	rm_wp_btw_fun_n_opn_par($arg_offset);
	brace_unbraced_ifelse_if_needed($arg_offset);

}

sub adjust_indent {
  my ($arg_offset) = @_;
  my $ind_level = 0;
  my $ind_char = "\t";
  my $seen_entry = 0;
  my $lines_length = $#file_lines + 1;

  for (my $i = 0; $i < $lines_length; $i++) {
	my $f_line = $file_lines[$i];

	if(grep(/^([[:alpha:]]+ main[^{]*$)/,$f_line)) {
		#print "seen entry\n";
	  $seen_entry = 1;
	}
	if(grep (/^(?:\s*(?:(?!\()(?:int|uint32_t|uint16_t|uint8_t|float|double|char|short|long long|long double|long|signed|_Bool|bool|enum|unsigned|void|complex|_Complex|size_t|time_t|FILE|fpos_t|va_list|jmp_buf|wchar_t|wint_t|wctype_t|mbstate_t|div_t|ldiv_t|imaxdiv_t|int8_t|int16_t|int32_t|int64_t|int_least8_t|int_least16_t|int_least32_t|int_least64_t|uint_least8_t|uint_least16_t|uint_least32_t|uint_least64_t|int_fast8_t|int_fast16_t|int_fast32_t|int_fast64_t|uint_fast8_t|uint_fast16_t|uint_fast32_t|uint_fast64_t|intptr_t|uintptr_t)\s*(?!\)))+ [[:word:]]+\s*\([[:print:]]+\))\s*$/,$f_line)) {
		#print "seen function entry \n";
		$seen_entry = 1;
	}
	if ($seen_entry == 1) {
	  my $opening_brace;
	  if ($f_line =~ /(^[[:blank:]]*(?={))({)[[:blank:]]*$/mg) {
		$opening_brace = $2;
		$file_lines[$i] = ($ind_char x $ind_level) . $opening_brace;
		$ind_level++;
		#print "indentation level: $ind_level:$f_line\n";
	  }
	  elsif($f_line =~ /^\s*(do)\s*(\{)\s*$/mg) {
		my $statement = $1 . " " . $2;
		$file_lines[$i] = ($ind_char x $ind_level) . $statement;
		$ind_level++;
		#print "found a do while \n";
		#print "statement: $statement\n";
		#print "indentation level: $ind_level:$f_line\n";
	  }
	  elsif($f_line =~ /\s*(\})\s*(while)\s*(\()\s?([[:graph:]]+)\s?(\);)$/mg) {
		my $statement = $1 . " " . $2 . " " . $3 . $4 . $5; 
		$ind_level = $ind_level - 1 >= 0 ? $ind_level - 1 : 0;
		$file_lines[$i] = ($ind_char x $ind_level) . $statement;
		#print "indentation level: $ind_level:$f_line\n";
	  }
	  elsif($f_line =~ /^\s*(else)\s*$/mg) {
		my $statement = $1 . " " . $2 . " " . $3; 
		#$adjust_ind_level = $ind_level - 1 >= 0 ? $ind_level - 1 : 0;
		$file_lines[$i] = ($ind_char x $ind_level) . $statement;
		#print "indentation level: $ind_level:$f_line\n";
		#print "else block seen \n";
	  }
	  elsif($f_line !~ /(^[[:blank:]]*(?={))({)[[:blank:]]*$/mg and $f_line !~ /(^[[:blank:]]*(?=}))(})[[:blank:]]*$/mg) {
		if($f_line =~ /^[[:blank:]]*([[:print:]]+(;|\)|:))/mg) {
		  my $statement = $1;
		  if (grep(/^\s*(?:(?:case [[:print:]]+|default\s*|goto\s*|error\s*|end\s*):)\s*$/,$f_line)) {
		#	print "a case or default statement found.\n";
			$file_lines[$i] = ($ind_char x ($ind_level - 1)) . $statement;
		  }
		  else{
			$file_lines[$i] = ($ind_char x $ind_level) . $statement;
		  }
		  #print "statement: $statement\n";
		  #print "indentation level: $ind_level:$f_line\n";
		}
	  }
	  elsif($f_line !~ /(^[[:blank:]]*(?=}))(})[[:blank:]]*$/mg) {
		my $closing_brace = $2;
		$ind_level = $ind_level - 1 >= 0 ? $ind_level - 1 : 0;
		$file_lines[$i] = ($ind_char x $ind_level) . $closing_brace;
		print "indentation level: $ind_level:$f_line\n";
	  }
	}

  }
  write_parsed_lines($arg_offset);
}

sub no_brace_indent {
  my ($arg_offset) = @_;
  my $ind_level = 0;
  my $ind_char = "\t";
  my $seen_entry = 0;
  my $l_count = 0;
  my $p_line = $l_count - 1 >= 0 ? $file_lines[$l_count - 1] : $file_lines[0];
  for my $f_line (@file_lines) {
	if ($f_line =~ /^(\s*)((?:else)?\s?if\s*\(.+\))\s*$/mg) {
	  $ind_level = 0;
	  my $existing_indent = $1;
	  if ($file_lines[$l_count + 1] !~ /^\s*{\s*$/) {
		$file_lines[$l_count] = $existing_indent . $2;
		#print "indentation level: $ind_level:$f_line\n";
		$ind_level++;
		#print "no brace indent on $f_line\n";
	  }
	}
	elsif ($f_line =~ /^(\s*)(else)\s*$/mg) {
	  $ind_level = 0;
	  my $existing_indent = $1;
	  my $statement = $2;
	  if ($file_lines[$l_count + 1] !~ /^\s*{\s*$/) {
		$file_lines[$l_count] = $existing_indent . $statement;
		#print "indentation level: $ind_level:$f_line\n";
		$ind_level++;
		#print "no brace indent on $f_line\n";
	  }
	}
	elsif($file_lines[$l_count - 1] =~ /(?:^((\s*)(?:else)?\s?if\s*\(.+\))\s*$)/mg) {
	  #print "existing indent of parent $2.\n";
	  my $existing_indent = $2;
	  if ($f_line =~ /^[[:blank:]]*([[:print:]]+(;|\)|:))/mg) {
		my $statement = $1;
		$file_lines[$l_count] = $existing_indent . ($ind_char x $ind_level) . $statement;
		#print "statement: $statement\n";
		#print "indentation level: $ind_level:$f_line\n";
	  }
	}
	elsif ($file_lines[$l_count - 1] =~ /^(\s*)else\s*$/mg) {
	  #print "existing indent of parent $2.\n";
	  my $existing_indent = $1;
	  if ($f_line =~ /^[[:blank:]]*([[:print:]]+(;|\)|:))/mg) {
		my $statement = $1;
		$file_lines[$l_count] = $existing_indent . ($ind_char x $ind_level) . $statement;
		#print "statement: $statement\n";
		#print "indentation level: $ind_level:$f_line\n";
	  }
	}
	$l_count++;
  }
   
  write_parsed_lines($arg_offset);
}

sub rm_trailing_wp {
  my ($arg_offset) = @_;
  my $l_count = 0;
  for my $f_line (@file_lines) {
	if ($f_line =~ /^(.*)(?<!\s)\s+$/mg){
		$f_line = $1;
		#print  "a trailing whitespace spotted.$f_line\n";
		$file_lines[$l_count] = $f_line;
	}
	if ($f_line =~ /[[:blank:]]*$/ and $' eq '{') {
	  $f_line =~ s/[[:blank:]]*$//m;
	  $file_lines[$l_count] = $f_line;
	}
	$l_count++;
  }
  write_parsed_lines($arg_offset);
}

sub separate_RD_tokens {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
	if (grep(/[^ ](?:==|!=|<=|>=|<|(?<!-)>|=)[^ ]/,$f_line)) {
	  $f_line =~ s/([^ ])(==|!=|<=|>=|<|(?<!-)>|=)([^ ])/$1 $2 $3/g;
	  $file_lines[$l_count] = $f_line;
	}
	if (grep(/[^ ](?:\&\&|\|\|)[^ ]/,$f_line)){
		#print "$1\n";
		$f_line =~ s/([^ ])(\&\&|\|\|)([^ ])/$1 $2 $3/g;
	}
	if ($f_line =~ /[[:graph:]],[[:graph:]]/g) {
	if ($f_line !~ /"[^"]+"/g) {
	if ($f_line =~ /(?<=[[:graph:]])(,)(?=[[:graph:]])/g) {
		if ($` =~ /^[^"]*"[^"]*"[^"]*/ or $' =~ /[^"]*"[^"]*"[^"]*$/ or (not grep(/"/,$f_line))) {
		#	print "comma separated tokens found\n";
			$f_line = $` . $1 . " " . $';
			$file_lines[$l_count] = $f_line;

		}
	}
	}
	}

	$l_count++;
  }
  write_parsed_lines($arg_offset);
}

sub format_ctrl_keywords {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
	if ($f_line =~ /^(\s*)((?:else)?\s*if|for|while|switch)(\(.*\))\s*$/mg) {
	  #print "an unseparated control keyword spotted.\n";
	  $f_line = $1 . $2 . " " . $3;
	  $file_lines[$l_count] = $f_line;
	}
	$l_count++;
  }

  write_parsed_lines($arg_offset);
}

sub cast_entry {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
		if ($f_line =~ /^(void|int)\s*(main)\s*\(\s*\)\s*$/){
		#	print "an uncasted entry point spotted.\n";
			$f_line = $1 . " " . $2 .  "(void)";
			$file_lines[$l_count] = $f_line;
		}
	$l_count++;
  }

  write_parsed_lines($arg_offset);
}

sub wrap_return {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
	if ($f_line =~ /^(\s*)(return)\s*(?!\()(?<= )(?! )(.+);$/mg) {
		$f_line = $1 . $2 . " " . "(" . $3 . ")" . ";";
		$file_lines[$l_count] = $f_line;
	  #print "an unwrapped return value spotted. $f_line\n";
	}
	$l_count++;
  }

  write_parsed_lines($arg_offset);
}

sub unpad_parentheses {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
	if ($f_line =~ /(\()\s+([[:print:]]+)(\))/mg) {
		$f_line = $` . $1 . $2 .  $3 . $';
		$file_lines[$l_count] = $f_line;
	  #print "a padded left parentheses spotted. $f_line\n";
	}
	if ($f_line =~ /(\()([[:print:]]+)\s+(\))/mg) {
		$f_line = $` . $1 . $2 .  $3 . $';
		$file_lines[$l_count] = $f_line;
		#print "a padded right parentheses spotted. $f_line\n";
	}
	$l_count++;
  }

  write_parsed_lines($arg_offset);

}

sub pad_defs {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
	if ($f_line =~ /(\s+(?:(?!\()(?:int|uint32_t|uint16_t|uint8_t|float|double|char|short|long long|long double|long|signed|_Bool|bool|enum|unsigned|void|complex|_Complex|size_t|time_t|FILE|fpos_t|va_list|jmp_buf|wchar_t|wint_t|wctype_t|mbstate_t|div_t|ldiv_t|imaxdiv_t|int8_t|int16_t|int32_t|int64_t|int_least8_t|int_least16_t|int_least32_t|int_least64_t|uint_least8_t|uint_least16_t|uint_least32_t|uint_least64_t|int_fast8_t|int_fast16_t|int_fast32_t|int_fast64_t|uint_fast8_t|uint_fast16_t|uint_fast32_t|uint_fast64_t|intptr_t|uintptr_t)\s*(?!\)))+[[:print:]]*;$)/mg) {
		if(not (grep (/(?:\s+(?:(?!\()(?:int|uint32_t|uint16_t|uint8_t|float|double|char|short|long long|long double|long|signed|_Bool|bool|enum|unsigned|void|complex|_Complex|size_t|time_t|FILE|fpos_t|va_list|jmp_buf|wchar_t|wint_t|wctype_t|mbstate_t|div_t|ldiv_t|imaxdiv_t|int8_t|int16_t|int32_t|int64_t|int_least8_t|int_least16_t|int_least32_t|int_least64_t|uint_least8_t|uint_least16_t|uint_least32_t|uint_least64_t|int_fast8_t|int_fast16_t|int_fast32_t|int_fast64_t|uint_fast8_t|uint_fast16_t|uint_fast32_t|uint_fast64_t|intptr_t|uintptr_t)\s*(?!\)))+[[:print:]]*;$)/,$file_lines[$l_count + 1]) or grep(/^\s*$/,$file_lines[$l_count + 1]))) {
			$f_line = $` . $1 . "\n";
			$file_lines[$l_count] = $f_line;
		#	print "an unpadded definition. $f_line\n";
		}
	}
	$l_count++;
  }

  write_parsed_lines($arg_offset);
}

sub rm_wp_btw_fun_n_opn_par {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
		if ($f_line =~ /^\s*((?:(?!\()(?:int|uint32_t|uint16_t|uint8_t|float|double|char|short|long long|long double|long|signed|_Bool|bool|enum|unsigned|void|complex|_Complex|size_t|time_t|FILE|fpos_t|va_list|jmp_buf|wchar_t|wint_t|wctype_t|mbstate_t|div_t|ldiv_t|imaxdiv_t|int8_t|int16_t|int32_t|int64_t|int_least8_t|int_least16_t|int_least32_t|int_least64_t|uint_least8_t|uint_least16_t|uint_least32_t|uint_least64_t|int_fast8_t|int_fast16_t|int_fast32_t|int_fast64_t|uint_fast8_t|uint_fast16_t|uint_fast32_t|uint_fast64_t|intptr_t|uintptr_t)\s*(?!\)))+ [[:word:]]+)\s+(\([[:print:]]+\))\s*$/mg) {
			$f_line = $1 . $2;
			$file_lines[$l_count] = $f_line;
		#	print "an tokens here are .$1\n$2 \n and \n$3\n";
		}
	$l_count++;
  }

  write_parsed_lines($arg_offset);
}

sub brace_unbraced_ifelse_if_needed {
  my ($arg_offset) = @_;
  my $l_count = 0;
	my %if_pts = (
	);

  for my $f_line (@file_lines) {
		if ($f_line =~ /^(\s+)if\s+\([[:print:]]+\)\s*$/m) {
		#	print "if line: \t $f_line \n";
			my $indent_level = length($1);
			$if_pts{"$l_count"} = [$indent_level,$f_line];
		}
	$l_count++;
  }

	foreach $key (keys %if_pts) {
	#	print "line: $key \n statements:\n";
		my @val  = @{$if_pts{$key}}; 
		my ($indent_level,$line) = @val;
		my @branch_pts = ();
		my $seen_wrapped = 0;
		my @wrapped_branch_pts = ();
		my @unwrapped_branch_pts = ();
		my $ind_char = "\t" x $indent_level;
		my $b_count = $key;

		push(@branch_pts,$b_count);
		#print  "b count : $b_count \t file lines : $#file_lines\n";

		for (; $b_count <= $#file_lines; $b_count++) {
		#	print "going through the file lines\n";
			if ($file_lines[$b_count] =~ /^(\s+)((?:else\s)?if \([[:print:]]+\)|else)\s*$/m) {
				$b_ind_level = length($1);
		#		print "branch indent level : $b_ind_level\t statement: $file_lines[$b_count]\n";
				if ($b_ind_level >= $indent_level and not ($b_ind_level == $indent_level && grep(/^\s+((?:for|if|while|switch)\s+\([[:print:]]+\)|do\s*{)\s*$/,$file_lines[$b_count]))) {
				if(grep(/^\s+(else(?:\s+if\s+\([[:print:]]+\))?)\s*$/),$file_lines[$b_count] and $b_ind_level == $indent_level) {
		#				print "branch found: $file_lines[$b_count]\t indent level: $b_ind_level\n";
						push(@branch_pts,$b_count);
				}
				}
				else {
			#		last;
				}
			}
		}


		for my $b_point (@branch_pts) {
			if(grep(/^\s+\{\s*$/,$file_lines[$b_point + 1])) {
				#print "a wrapped branch found next to : $file_lines[$b_point] \t and it's $file_lines[$b_point + 1]\n";
				$seen_wrapped = 1;
				last;
			}
		}

		if ($seen_wrapped == 1) {
			for my $b_point (@branch_pts) { 
				#print "branch points: \n\t $file_lines[$b_point]\n";
				if(grep(/^\s+\{\s*$/,$file_lines[$b_point + 1])) {
					push(@wrapped_branch_pts,$b_point);
				}
			}
		}

		for my $b_point (@branch_pts) {
			if(not grep(/^$b_point$/,@wrapped_branch_pts)) {
		#		print "unwrapped $file_lines[$b_point]\n";
				push(@unwrapped_branch_pts,$b_point);
			}
		}

		for my $ub_point (@unwrapped_branch_pts) {
			my $wrapped =   $file_lines[$ub_point] . "\n" . $ind_char . "{" .  "\n" . $file_lines[$ub_point + 1] . "\n" . $ind_char . "}"; 
			$file_lines[$ub_point] = $wrapped;
			$file_lines[$ub_point + 1] = "$REMOVAL_PLACEHOLDER";
		#	print "unwrapped: $file_lines[$ub_point]\n";
		}

		for my $wb_point (@wrapped_branch_pts) {
		#	print "wrapped: $file_lines[$wb_point]\n";
		}

	}

  write_parsed_lines($arg_offset);
	
}

sub multi_parse_and_chomp {
  my $i;
  my @args = @_;
  my $arg_offset = $args[0];
  $i = $arg_offset ? $i + $arg_offset : 0;
  for(; $i < $parameters; $i++) {
	parse_and_chomp($ARGV[$i]);
  }
}

sub update_file_lines {
  my ($arg_offset) = @_;
  multi_parse_and_chomp($arg_offset);
}

sub handle_opt_error {
  my @args = @_;  
  my $file_opt = $args[0];
#ERROR HANDLING
  if(not grep(/^-[^\s-]+$/,$file_opt)) {
	 print "error: invalid option syntax! 1";
	 exit 1;
  }
  if(grep(/([[:alpha:]])\1/,$file_opt)) {
	print "error: recurring options!";
	exit 1;
  }
  if(grep(/lu/,$file_opt) or grep(/ul/,$file_opt)) { 
	print "error: logically conflicting options!";
	exit 1;
  }
  if(grep(/^-.*[[:digit:]]/,$file_opt)) {
	print "error: invalid option syntax!";
	exit 1;
  }
#END OF ERROR HANDLING
}

sub eval_file_opt {
  my @args = @_;
  my @opt_list = @args;

}

sub validate_opt_length {
  my ($file_opt, $opt_len, @opt_list) = @_;
  printf "args: @_\n";
  #print " file opt: $file_opt\n opt list: @opt_list\n opt len : $opt_len\n"
  #if(($opt_len == 3 or $opt_len == 2) and (index (join("",@opt_list),'-') eq 0)) {
	#handle_opt_error($file_opt);
	#multi_parse_and_chomp(1);
	#eval_file_opt(@opt_list);
	#print "two parameter argument including options\n";
  #}
}

#END OF SUB-ROUTINES

if($parameters == 1) {
  # parseFile [FILE]
  $file_name = $ARGV[0];
  if(grep(/^-.*/,$file_name)) {
		print "invalid single argument!\n";
		exit 1;
  }
	format_file(0);
  #print "one parameter argument\n";
}
elsif($parameters == 2) {
  # parseFile [...OPTIONS] [FILE]
 
  my $file_opt = $ARGV[0];
  my @opt_list = split(/(?=[[:graph:]])(?<=[[:graph:]])/,$file_opt);
  $file_name = $ARGV[1];
  my $opt_len = scalar(@opt_list);
  # To make sure that these are not 2 or 3-length file names , that they are indeed options
  validate_opt_length($file_opt, $opt_len, @opt_list);
  if(($opt_len == 3 or $opt_len == 2) and (index (join("",@opt_list),'-') eq 0)) {
	handle_opt_error($file_opt);
	multi_parse_and_chomp(1);
	eval_file_opt(@opt_list);
	#print "two parameter argument including options\n";
  }
  # In cases where they are results of pathname expansions and their names are not preceeded by -
  elsif (not (grep(/^-.*/,$ARGV[0]) or grep (/^-.*/,$ARGV[1]))) {
	multi_parse_and_chomp();
	#print "pathname expanded";
  }
  else {
	print "error: \n.1 unrecognizable synopsis specified 2-parameter mode\n\t check the man page for guide or visit our official documentation at https://github.com:HazelDaniel/perl-practice\n";
  }

}
else {
  # multiple file mode with/without options:
  # ERROR HANDLING
  if(grep (/^((?<=\b)\w[[:graph:]]*\s?)+$/,"@ARGV")) {
	# no options are provided. only pathname expansions or file lists
	multi_parse_and_chomp();
	#print "multi parameter argument (pathnames only)\n";

  }elsif(grep (/^(-[[:alpha:]]{1,2}\s)?((?<=\b)\w[[:graph:]]*\s?)+$/,"@ARGV")) {
	# options are provided alongside file lists or expanded pathnames 
	my $file_opt = $ARGV[0];
	my @opt_list = split(/(?=[[:graph:]])(?<=[[:graph:]])/,$file_opt);
	$file_name = $ARGV[1];
	my $opt_len = scalar(@opt_list);
	multi_parse_and_chomp(1);
	eval_file_opt(@opt_list);
	#print "multi parameter argument (options provided)\n";
  }
  elsif (grep(/^--[[:graph:]]+/,$ARGV[1])) {
	# parseFile [...OPTIONS] [--...LONG-OPTIONS] [FILE]
	
	my $file_opt = $ARGV[0];
	my @opt_list = split(/(?=[[:graph:]])(?<=[[:graph:]])/,$file_opt);
	my $opt_len = scalar(@opt_list);
	validate_opt_length($file_opt, $opt_len, @opt_list);
	# a repeated validation logic about to happen. why not find a way to export that into a re-usable function
	my $file_param = $ARGV[1];
	my @param_list = split(/(?=[[:graph:]])(?<=[[:graph:]])/,$file_param);
	my $param_string = join("",@param_list);
	my @param_text_naive = split(/(?<=--)(?=[[:alpha:]])/,$param_string);
	my @param_text = split(/(?==)/,$param_text_naive[1]);
	my $param = $param_text[0];
	my $param_val_naive = $param_text[1];
	my @param_val = split(/((?<==)(?=[[:alnum:]])|(?<==)(?=\'))/,$param_val_naive);
	my $val = $param_val[2];
	print "param val naive : $param_val_naive\n";
	print "param text: $param\n";
	print "param val: $val\n";
	print "long parameter argument\n";

	if (not $val) {
	  print "no parameter value provided\n";
	  exit 1;
	}
  }
  else {
	print"error: \n.1 unrecognizable synopsis specified multi-parameter mode\n\t check the man page for guide or visit our official documentation at https://github.com:HazelDaniel/perl-practice\n";
	exit;
  }
}

sub remove_blanks {
  my ($arg_offset) = @_;
  my $l_count = 0;

  for my $f_line (@file_lines) {
		if ($f_line =~ /(^\s*$)/mg) {
			if (not grep (/^#/,$file_lines[$l_count - 1])) {

			if(not grep(/^([[:alpha:]]+ main[^{]*$)/,$file_lines[$l_count + 1])) {
				if( not grep (/^(?:\s*(?:(?!\()(?:int|uint32_t|uint16_t|uint8_t|float|double|char|short|long long|long double|long|signed|_Bool|bool|enum|unsigned|void|complex|_Complex|size_t|time_t|FILE|fpos_t|va_list|jmp_buf|wchar_t|wint_t|wctype_t|mbstate_t|div_t|ldiv_t|imaxdiv_t|int8_t|int16_t|int32_t|int64_t|int_least8_t|int_least16_t|int_least32_t|int_least64_t|uint_least8_t|uint_least16_t|uint_least32_t|uint_least64_t|int_fast8_t|int_fast16_t|int_fast32_t|int_fast64_t|uint_fast8_t|uint_fast16_t|uint_fast32_t|uint_fast64_t|intptr_t|uintptr_t)\s*(?!\)))+ [[:word:]]+\s*\([[:print:]]+\))\s*$/,$file_lines[$l_count + 1])) {
					$f_line = $REMOVAL_PLACEHOLDER;
					$file_lines[$l_count] = $f_line;
				}
			}

			}

		}
		$l_count++;
  }

  write_parsed_lines($arg_offset);
}

=for

EDGE CASES:
  when parameter length satisfies the above checks but due to a pathname expansion or a command substitution
  when pathname expands to n parameters
  when pathname expands to n parameters and options are provided
  when pathname expands to n parameters and long options are provided

=cut
