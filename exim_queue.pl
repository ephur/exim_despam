#!/usr/local/bin/perl
# Author: Richard Maynard
# Created:   March 22, 2002
# Updated:   March 27, 2002
#############################

##############################
# Declare variables and mods #
##############################
# Force good code, okay to remove once deployed
use strict;

# The working version number
my $version="1.6.1";

# Unbuffer stdout, this is important for SSH connections.
select((select(STDOUT), $|=1)[0]);

if((defined(&option("--help"))) || (defined(&option("-h")))){
  &HelpMsg;
  exit(0);
}

# Path to the exim queue, specify with --spool
my ($exim_q_path);
if(defined(&option("--spool"))){
  ($exim_q_path)=&option("--spool");
} else {  
  $exim_q_path='/ms/var/spool/exim/input';
}


# Other global variables that will be used.
my ($opt, $param);
my (%message, $message); 
my (@qdirs, $qdir);
my $nuke_count=0;
my $command;
my $thisbox=`uname -n`;
chomp($thisbox);

# Read the contents of the mail spool
read_queue();

# If a -[sfi] was passed on the command line go into command line mode
if(grep(/^-[sfi]$/, &option())){
  my(%option_cmds);
  $option_cmds{"-i"}="ip";
  $option_cmds{"-s"}="subject";
  $option_cmds{"-f"}="from";

  foreach $opt(grep(/^-[sfi]$/, &option())){
    if(scalar(&option($opt)) == 0){
      &sortby($option_cmds{$opt});
    } else {
      foreach $param(&option($opt)){
        if(defined(&option("--force"))){
          &nuke_spam($option_cmds{$opt}, $param);
        } else { 
          print(STDOUT "\nDo you really want to kill all spam for ".$option_cmds{$opt}." matching ".$param." (Y/N): "); 
          chomp($command=<STDIN>);
          if($command =~ /^[Yy]{1}[Ee]{0,1}[Ss]{0,1}$/){
            &nuke_spam($option_cmds{$opt},$param);
          }
        }
      }
    }
  }
  if(defined(&option("-o"))){
    $nuke_count = $nuke_count/1000;
    my $outfile;
    ($outfile)=&option("-o");
    if(open(OUTFILE, "< $outfile")){
      my $outfile_count;
      chomp($outfile_count=<OUTFILE>);
      close(OUTFILE);
      if(open(OUTFILE, "> $outfile")){   
        $outfile_count+=$nuke_count;
        print(OUTFILE $outfile_count."\n");
        print(STDOUT "A total of " . ($outfile_count*1000) ." spams have been nuked by you when tracking deletions.\n");
        close(OUTFILE);
        if(open(OUTFILE, "< /home/ephur/spam/spam_kill_global")){
          chomp($outfile_count=<OUTFILE>);
          close(OUTFILE);
          if(open(OUTFILE, "> /home/ephur/spam/spam_kill_global")){
            $outfile_count+=$nuke_count;
            print(OUTFILE $outfile_count."\n");
            print(STDOUT "A total of " . ($outfile_count*1000) . " spams have been nuked by everyone tracking deletions.\n");
            close(OUTFILE); 
          }
        }
      } else { 
        print (STDERR "Error writing output file $outfile\n");
      }
    } else { 
      print (STDERR "Error reading output file $outfile\n");
    } 
    print(STDOUT "You killed " . ($nuke_count*1000) . " spams this session.");
  }

exit(0);
}


# if there were no command line options set go into gui mode
while(1){
  my $order;
  my (%menu_cmds)=("1 s", "Subject",
                   "2 i", "IP",
                   "3 f", "From",
                   "4 r", "Reread Spool",
                   "5 q", "Quit");
  system(clear);
  print(" "x79, "\n"x25);
  print("[H"); 
  print("^[[2J"); 
  print("\n\n\n\n\n");
  foreach $param(sort(keys(%menu_cmds))){
    ($order, $param)=split(/\s+/,$param);
    $menu_cmds{$order." ".$param} =~ /^($param)(.*)$/i;
    print("    [7m$1[0m$2\n");
  } 
  #print("    [7mS[0mubject.\n");
  #print("    [7mI[0mP Address.\n");
  #print("    [7mF[0mrom.\n");  
  #print("    [7mR[0mescan spool.\n");
  #print("    [7mQ[0muit.");
  print("[H");
  print("Exim Queue Cleaning Util (v$version). Currently ".scalar(keys(%message))." headers on $thisbox.\n");
  print("="x79,"\n\n");
  print("How would you like to view the queue (S/I/F/R/Q): ");
  chomp($command=<STDIN>);
  if ($command =~/^[Qq]/){
    print("[H");
    print("[2J");
    if(defined(&option("-o"))){
      $nuke_count=$nuke_count/1000;
      my $outfile;
      ($outfile)=&option("-o");
      if(open(OUTFILE, "< $outfile")){
        my $outfile_count;
        chomp($outfile_count=<OUTFILE>);
        close(OUTFILE);
        if(open(OUTFILE, "> $outfile")){   
          $outfile_count+=$nuke_count;
          print(OUTFILE $outfile_count."\n");
          print(STDOUT "A total of " . ($outfile_count*1000) . " spams have been nuked by you when tracking deletions.\n");
          close(OUTFILE);
          if(open(OUTFILE, "< /home/ephur/spam/spam_kill_global")){
            chomp($outfile_count=<OUTFILE>);
            close(OUTFILE);
            if(open(OUTFILE, "> /home/ephur/spam/spam_kill_global")){
              $outfile_count+=$nuke_count;
              print(OUTFILE $outfile_count."\n");
              print(STDOUT "A total of " . ($outfile_count*1000) . " spams have been nuked by everyone tracking deletions.\n");
              close(OUTFILE); 
            }
          }
        } else { 
          print (STDERR "Error writing output file $outfile\n");
        }
      } else { 
        print (STDERR "Error reading output file $outfile\n");
      } 
    }
    print("You killed " . ($nuke_count*1000) . " spam messages this session.\n");
    exit(0);; 
  }
  elsif ($command =~ /^[Ss]$/){
    sortby("subject"); 
  }
  elsif ($command =~ /^[Ii]$/){
    sortby("ip"); 
  }
  elsif ($command =~ /^[Ff]$/){
    sortby("from");
  }
  elsif ($command =~ /^[Rr]$/){
  print(STDOUT "Refreshing spool, one moment...");
  read_queue();
  } 
}

sub sortby{
  my $exit_sub;
  until($exit_sub){
    my (%sorthash, $sortkey, $sortby, $usersort, $sortlist, @sortlist); 
    my $listcount=0;
    $sortby = $_[0];
    foreach $message(keys(%message)){
      $sortkey = $message{"$message"}{"$sortby"};
      if(defined($sorthash{"$sortkey"}) && defined($sortkey)){ 
        $sorthash{"$sortkey"}{"count"}+=1;
      } else { 
        $sorthash{"$sortkey"}{"count"}=1;
        $sorthash{"$sortkey"}{"id"}=$message;
      }
    }
    print("[2J");
    print("[H");
    foreach $sortkey(sort({ $sorthash{$a}{"count"} <=> $sorthash{$b}{"count"} }(keys(%sorthash)))){
      if($sorthash{"$sortkey"}{"count"} >= 25){
      $sortlist[$listcount] = $sortkey;
      $listcount++;
      print($listcount.": ".$sortkey." (".$sorthash{"$sortkey"}{"count"}." matches)\n"); 
      }
    }
    print(STDOUT "_"x79,"\n");
    $command=&GetInput("", "(V)iew", "(R)emove", "(B)ack to main");
    if ($command eq "B"){
      $exit_sub=1;
    } elsif ($command eq "V"){
      print(STDOUT "Which item number do you wish to view: ");
      chomp($usersort=<STDIN>);
      $usersort--;
      if($usersort =~ /^\d.*$/ && defined($sortlist[$usersort])){
        my $line;
        foreach $message(keys(%message)){
          my $linecount;
          if($message{$message}{$sortby} eq $sortlist[$usersort]){ 
            unless (open(SPAM, "< ".$message{$message}{"path"}."/".$message{$message}{"id"}."-D")){
              delete $message{$message};
              next;
            } 
            while(($line=<SPAM>) && ($linecount <= 200)){
              $linecount++; 
              print (STDOUT $line);
            }  
            close(SPAM);
            print("_"x79,"\n");
            if(defined(&option("--from"))){
              $command=&GetInput("","(R)emove","(M)ore Spam","(H)eader","(A)buse Mail","(B)ack to main");
            } else {
              $command=&GetInput("","(R)emove","(M)ore Spam","(H)eader","(B)ack to main");
            }
            if($command eq "B"){
              $exit_sub=1;
              last;
            } elsif($command eq "A"){
              &AbuseMail($message{$message}{"id"});
              last;
            } elsif($command eq "R"){
              nuke_spam($sortby,$sortlist[$usersort]); 
              last;
            } elsif ($command eq "H") { 
              open(SPAM, "< ".$message{$message}{"path"}."/".$message{$message}{"id"}."-H");
              while($line=<SPAM>){
                print(STDOUT $line);
              } 
              $command=&GetInput("", "(R)emove", "(M)ore spam", "(B)ack to main");
              if($command eq "R"){
                nuke_spam($sortby,$sortlist[$usersort]);
                last;
              } elsif ($command eq "B"){  
                $exit_sub=1;
                last;
              } 
            } elsif ($command eq "R") { 
              last; 
            }    
          }
        } 
      }else{
        print(STDOUT "Sorry, that doesn't appear to match the numbers I know about.\n<Press enter to return>");
        $usersort=<STDIN>;
      }
    
    } elsif ($command eq "R" || $command eq "r") {
      print(STDOUT "Enter the number of the spam(s) you would like to delete: ");
      chomp($usersort=<STDIN>); 
      my @userdels;
      @userdels=split(/\s+/,$usersort); 
      foreach $usersort(@userdels){
        $usersort--;
        if($usersort =~ /^\d+$/ && defined($sortlist[$usersort])){  
          nuke_spam($sortby, $sortlist[$usersort]);
        }else{
          print(STDOUT "Sorry, that doesn't appear to match the numbers I know about.\n<Press enter to return>");
          $usersort=<STDIN>;
        }
      } 
    } 
  }
}

sub read_queue{
  %message = undef;
  my $q_dir_count=1;
  opendir(EXIMQDIR, $exim_q_path) || die "Couldn't open the defined exim queue path: $exim_q_path\n";
  @qdirs = grep(!/^\./, readdir(EXIMQDIR));
  closedir(EXIMQDIR);

  foreach $qdir(sort(@qdirs)){
    print("[H");
    print("[2J");
    print("Reading queue dir: $qdir (".$q_dir_count." of ".scalar(@qdirs).")");
    if(opendir(SUBDIR, "$exim_q_path/$qdir")){
      foreach $message(grep(/.*-H$/,readdir(SUBDIR))){
        chomp($message);
        chop($message); 
        chop($message);
        $message{"$message"}{"path"}="$exim_q_path/$qdir";  
        $message{"$message"}{"id"}="$message";
        open(HEADER, "< ".$message{$message}{"path"}."/".$message{$message}{"id"}."-H") || warn "Header no longer valid"; 
        while(<HEADER>){
          if(/From:\s(.*)$/){
            $message{$message}{"from"} = $1;
          }      
          elsif(/Subject:\s(.*)$/){
            $message{$message}{"subject"} = $1;
          }
          elsif(/^-host_address\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/){
            $message{$message}{"ip"} = $1;
          }
          if($message{"$message"}{"from"} && $message{"$message"}{"ip"} && $message{"$message"}{"subject"}){ 
            last;
          }
        }
        close(HEADER);
      }
      $q_dir_count++;
      closedir(SUBDIR);
    }
  }
}

sub nuke_spam{ 
  my $delstring = $_[1];
  my $delby = $_[0];
  my $exim_return;
  my @lsofoutput;
  my ($pid, $command, $line);
  foreach $message(keys(%message)){
    if($message{$message}{$delby} eq "$delstring"){
      # print(STDOUT `/ms/svc/smtp/bin/exim -Mrm $message{$message}{"id"}`); 
      $exim_return=`/ms/svc/smtp/bin/exim -Mrm $message{$message}{"id"}`; 
      print(STDOUT $exim_return); 
      if ($exim_return =~ /removed/){
        $nuke_count++;
      }
      delete $message{$message};
    }
  } 
  if ($delby eq "ip"){
    @lsofoutput=`lsof -i TCP\@$delstring | awk \'\{print \$1 \" \" \$2\}\' | sort | uniq`;
    while ($line=shift(@lsofoutput)){
      if ($line =~ /^([^\s]+)\s+(\d+)/){
        $pid=$2;
        unless(defined(&option("--force"))){
          print(STDOUT "The IP $delstring is running a $1($2) command, kill it (Y/N): ");
          chomp($command=<STDIN>);
        }
        if(($command =~ /^[Yy]/) || (defined(&option("--force")))){
          print(STDOUT `kill $pid`);
        }
      }
    } 
  } 
  unless(defined(&option("--force"))){
    print("<Hit Enter to continue>");
    chomp($command=<STDIN>);
  }
  return 0;
}

sub AbuseMail{
  my $abuse_id = $_[0];
  my $abuse_ip = $message{$abuse_id}{"ip"};
  my $abuse_msg;
  my $trace_msg;
  my $host_msg;
  my $whois_msg;
  my $spam_head;
  my $spam_body;
  my $ccaddr;
  my $read;
  my ($fromaddr)=&option("--from");
  my $toaddr;
  if(defined(&option("--to"))){
    ($toaddr)=&option("--to");
  } else {
    $toaddr="root\@localhost";
  }

  my $line="---------------------------------------------------------------------\n";
  
  # print(STDOUT "Getting whois information.\n");
  # $whois_msg=`/bin/whois -h whois.arin.net $abuse_ip`;
  # print(STDOUT "Getting host information.\n");
  # $host_msg=`/usr/local/bin/host $abuse_ip`;
  # print(STDOUT "Getting traceroute information.\n");
  # $trace_msg=`/usr/local/bin/traceroute $abuse_ip`;
  # $trace_msg=&TraceRoute($abuse_ip);
  print(STDOUT "Opening header information.\n"); 
  unless(open(SPAM_HEAD, "< ".$message{$abuse_id}{"path"}."/".$message{$abuse_id}{"id"}."-H")){
    return;
  }
  my $start_header;
  while($read=<SPAM_HEAD>){
    $start_header=1 if($read =~ /Received: from/);
    $spam_head .= $read if($start_header);
  } 
  close(SPAM_HEAD);
  
  print(STDOUT "Opening spam body.\n");
  unless(open(SPAM_BODY, "< ".$message{$abuse_id}{"path"}."/".$message{$abuse_id}{"id"}."-D")){
    return;
  } 
  while($read=<SPAM_BODY>){ 
    $spam_body .= $read;
  }
  close(SPAM_BODY);

  print(STDOUT "Generating mail to abuse.\n"); 
  $abuse_msg .= "To: $toaddr\n";
  if(defined(&option("--cc"))){
    ($ccaddr)=&option("--cc");
    $abuse_msg .= "To: $ccaddr\n";
  }
  $abuse_msg .= "From: $fromaddr\n";
  $abuse_msg .= "Subject: A spammer on our network.\n";
  $abuse_msg .= "\n";
  $abuse_msg .=  "Abuse, \n\t The following spam was found queued for delivery\n";
  $abuse_msg .= "on $thisbox. One of the smtp servers. Please attempt\n";
  $abuse_msg .= "to eliminate this spammer at the source.\n";
  $abuse_msg .= "\tIncluded in this email are the complete exim headers, and complete body of the messages.\n";
  $abuse_msg .= "\n\n\n".$line;
  $abuse_msg .= "Here is the complete exim header of the offending message\n";
  $abuse_msg .= $line.$spam_head."\n\n\n".$line;
  $abuse_msg .= "Here is the complete body of the offending message\n";
  $abuse_msg .= $line."\n".$spam_body."\n\n\n".$line;
  $abuse_msg .= "Here is the whois info from arin on the IP of this spam\n";
  $abuse_msg .= $line.$whois_msg."\n\n\n".$line;
  $abuse_msg .= "Here is the host info on the IP of this spam\n";
  $abuse_msg .= $line.$host_msg."\n\n\n".$line;
  $abuse_msg .= "Here is a tracerout to the offending IP from the mailserver were spam was found\n";
  $abuse_msg .= $line.$trace_msg."\n\n\n".$line;
 
  print(STDOUT "Sending mail to abuse.\n"); 
  if(defined(&option("--cc"))){
   open(ABUSE_OUT, "|/bin/mail $toaddr $ccaddr") || die;
  } else { 
   open(ABUSE_OUT, "|/bin/mail $toaddr") || die;
  }
  print(ABUSE_OUT $abuse_msg);
  close(ABUSE_OUT);
 
}

sub GetInput{
  my $prompt = shift(@_);
  my @valid_options = @_;
  my @cmds;
  my $valid_option;
  my $counter=0;
  my ($user_input, $valid_user_input);

  foreach $valid_option(@valid_options){
    $valid_option =~ /\((.*)\)/;
    $cmds[$counter] = $1;
    $counter ++;
  } 

  $prompt .= " ".join(", ", @valid_options);
  #print($prompt);
  #@cmds = split(/(^|\))[^\(]+(\(|$)/,$prompt);
  #print ("DEBUG -> @cmds[2]\n");
  $prompt .= " (".join("|",@cmds).") :" ; 
  $prompt =~ s/\(([^\)]+)\)/"(".uc($1).")"/eg ;
  $prompt =~ s/^\s*//;

  until ($valid_user_input){
    print(STDOUT $prompt); 
    chomp($user_input=<STDIN>);
    foreach $valid_option(@cmds){
      if (uc($user_input) eq $valid_option){
        $valid_user_input=1; 
        return uc($user_input);
      }  
    }
  } 
  
}

{
  my($opts_set, %opts);

  sub option{
    my($opt) = shift @_;
    &setoptions if(!$opts_set);
    if(exists($opts{$opt})){
      # push(@{$opts{$opt}}, undef) unless($opts{$opt});
      @{$opts{$opt}}=() unless($opts{$opt});
      return(@{$opts{$opt}}); 
    }
    return(keys %opts) if(!$opt);
    return(undef);

  }
  
  sub setoptions{
    my($arg);
    my($option) = "-";
    foreach $arg(@ARGV){
      if($arg =~ /^-/){
        $option=$arg;
        $opts{$option}=() if(!exists($opts{$option}));
      } else {
        push(@{$opts{$option}}, $arg);
        $option = "-";
      }
    }  
    $opts_set = 1;
  }
}

sub TraceRoute{
  my $trace_ip = $_[0];
  my $trace_output; 
  my $line;

  open(TRACEROUTE, "traceroute -w 2 $trace_ip 2>\&1|");
  while($line=<TRACEROUTE>){ 
    $trace_output .= $line;     
    if($line =~ /(\*\s+){3}/){
      $trace_output .= "Trace did not complete...\n"; 
      last;
    }
  }
  return($trace_output);
}


sub HelpMsg(){
  print(STDOUT "Exim Queue Cleaning utility, version $version.\n\n");
  print(STDOUT "\tShort Options\n");
  print(STDOUT "\t -h Display this help screen.\n");
  print(STDOUT "\t -i Go directly to the sort by IP screen, you may also use\n");
  print(STDOUT "\t    -i IP and have it automatically delete entries from that ip.\n");
  print(STDOUT "\t    You may use -i on the command line to remove multi IP's by doing\n");
  print(STDOUT "\t    -i IP -i IP -i IP\n");
  print(STDOUT "\t -s Same as -i, but displays by subject.\n");
  print(STDOUT "\t -f Same as -i, but displays by from address.\n");
  print(STDOUT "\t -o Output file, this will be used to keep track of your total spam kill count.");
  print(STDOUT "\n\n");
  print(STDOUT "\tLong Options\n");
  print(STDOUT "\t --help Display this help screen.\n");
  print(STDOUT "\t --force In command line mode (-i/-s/-f) it will auto delete\n");
  print(STDOUT "\t    anything that matches. In interactive mode it will force\n");
  print(STDOUT "\t    kills of processes running by spammers when IP is selected.\n");
  print(STDOUT "\t --from REQUIRED to use the Abuse Mail option. This should be your\n");
  print(STDOUT "\t    \"from\" email address in the abuse complaint that is sent.\n");
  print(STDOUT "\t --to OPTIONAL for using with the abuse mail option, this will\n");
  print(STDOUT "\t    specify a to address for the spam complaint mail. The default\n");
  print(STDOUT "\t    is root\@localhost.\n");
  print(STDOUT "\t --cc OPTIONAL for using with the abuse mail option, this will\n");
  print(STDOUT "\t    allow you to specify a carbon copy recipient for abuse mail\n");
  print(STDOUT "\t --spool With this switch you can specify an alternate spool directory\n");
  print(STDOUT "\t    for exim, the default is: /ms/var/spool/exim/input\n\n\n");
}
