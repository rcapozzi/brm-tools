#!/usr/bin/perl


my $state = -1;
my $prev_state = -1;
my $log_level;
my $pid = -1;
my $src_file;
my $msg;
my @stack = ();
my $ruler = sprintf("#%s\n", "-" x 60);

while (<>) {
    if (/^[\s\t\0]*([DEW])\s+(.*?)\s+/){
#print "header line: $_";
      $log_level = $1;
      if (/ cm:(\d+)/){
        $pid = $1;
      };
      if ($state != -1){
        printf "%s %s\n", $log_level, $message;
        printf "$ruler" if $state == 4;
        printf join('', @stack);
#        printf "$ruler" if $state == 4;
      }
      $state = 1;
      @stack = ();

    } elsif ($state == 1 && /^([\s\t\0]*)(.*$)/){
#print "message line: $_";
      $state = 2;
      $message = $2;
    } elsif (/^# number of field /){
      $state = 3;
               #      1    2    3     4
    } elsif ($state > 2 && /^[\s\t\0]*(\d+)\s+(\w+)\s+(\w+)\s+\[(\w+)\] (.*?)$/){
      $state = 4;
      $fld_level = $1;
      $padding = " " x ($fld_level * 2);
      $fld_name = "${padding}$2";
      $fld_type = $3;
      $fld_idx = $4;
      $fld_value = $5;
      $fld_value = "" if $fld_type =~ /ARRAY|SUBSTRUCT/;
      my $line = sprintf("%s %-35s %10s [%d] %s\n", $fld_level, $fld_name, $fld_type, $fld_idx, $fld_value);
      push(@stack, $line);
    } else {
#print "Unknown line: $_";
      $state = -1;
      push(@stack, $_);
    }

    $prev_state = $state;
  }

  printf "$ruler";
  printf "%s %s\n", $log_level, $message;
  printf join('', @stack);
