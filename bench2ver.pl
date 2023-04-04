#!/usr/bin/perl

use strict;
use POSIX();
use Cwd qw(); 
use warnings;
use Cwd qw(cwd); 
#use diagnostics;
#use Math::Matrix;
use Path::Tiny qw(path);
use Storable qw(dclone);
use Time::HiRes qw(time);
use Term::ANSIColor qw(:constants);

my $arg_ok = 1;
my $arg_cnt = 0;

my $file_net = "";

while (1){
  if (defined $ARGV[$arg_cnt]){
    if ($ARGV[$arg_cnt] eq "-h" or $ARGV[$arg_cnt] eq "-help"){
      $arg_ok = 0;
    }
    else {
      if (index($ARGV[$arg_cnt], "-f=") != -1){
        $file_net = substr($ARGV[$arg_cnt], 3, length($ARGV[$arg_cnt])-3);
      }
      else{
        $arg_ok = 0;
      }
    }
  }
  else{
    last;
  }

  $arg_cnt++;
}

if ($arg_ok == 0){
  help_part();
}
else {
  main_part();
}

sub help_part{
  printf "##################################################################################### \n";
  printf "# Usage:       perl bench2ver.pl -f=<FileName>                                      # \n";
  printf "# net:         Name of the bench file which includes a locked design                # \n";
  printf "# Description: This code converts the locked bench file to a Verilog file using ABC # \n";
  printf "##################################################################################### \n";
}

sub skip_spaces_forward{
  my ($the_string, $the_offset) = @_;
  my $the_length = length($the_string);

  while (index($the_string, " ", $the_offset) eq $the_offset) {
    $the_offset++;
    if ($the_offset > $the_length) {
      last;
    }
  }

  return $the_offset;
}

sub skip_spaces_backward{
  my ($the_string, $the_offset) = @_;

  while (index($the_string, " ", $the_offset) eq $the_offset) {
    $the_offset--;
    if ($the_offset < 0) {
      last;
    }
  }

  return $the_offset;
}

sub is_full_nonzero{
  my ($the_cnt, $the_arr) = @_;

  my $the_val = 1;

  for (my $i=0; $i<$the_cnt; $i++){
    if ($the_arr->[$i] != 0){
      $the_val = 0;
      last;
    }
  }

  return ($the_val);
}

sub print_array{
  my ($the_label, $the_cnt, $the_arr_ref) = @_;

  print "$the_label: ";
  for (my $i = 0; $i < $the_cnt; $i++){
    print "$the_arr_ref->[$i] ";
  }
  print "\n";
}

sub int2sign{
  my ($the_int, $the_len) = @_;
  #print "the_int: $the_int ";

  my @the_rep = ();

  if ($the_int < 0){
    $the_int = 2**$the_len - abs($the_int);
  }
  #print "act_int: $the_int the_rep: ";

  foreach my $i (1 .. $the_len){
    $the_rep[$i] = 0;
  }

  my $the_index = 0;
  while ($the_int > 1){
    my $the_val = $the_int % 2;
    $the_rep[$the_index] = $the_val;
    $the_int = ($the_int - $the_val) / 2;
    $the_index++;
  }

  $the_rep[$the_index] = $the_int;

  return (@the_rep);
}

sub int2bin{
  my ($the_int, $the_len) = @_;

  my @the_rep = ();

  foreach my $i (1 .. $the_len){
    $the_rep[$i] = 0;
  }

  my $the_index = 0;
  while ($the_int > 1){
    my $the_val = $the_int % 2;
    $the_rep[$the_index] = $the_val;
    $the_int = ($the_int - $the_val) / 2;
    $the_index++;
  }

  $the_rep[$the_index] = $the_int;

  return (@the_rep);
}

sub find_backforward_slash{
  my ($the_string) = @_;

  my $is_bfs = -1;

  if (index($the_string, "/") != -1){
    $is_bfs = 1;
  }
  elsif (index($the_string, "\\") != -1){
    $is_bfs = 0
  }

  return ($is_bfs);
}

sub extract_file_name_directory{
  my ($the_file) = @_;

  my ($file_name, $file_dir) = "";
  my $the_cwd = cwd;

  #Find the bfs in the current working directory
  my $is_bfs = find_backforward_slash($the_cwd);

  ##Extract the file name and directory
  my $the_index = length($the_file);
  while (substr($the_file, $the_index, 1) ne "." and substr($the_file, $the_index, 1) ne "\\" and substr($the_file, $the_index, 1) ne "/"){
    $the_index--;

    if ($the_index < 0){
      last;
    }
  }
  if ($the_index <= 0){
    $file_name = $the_file;
    $file_dir = $the_cwd;
    if ($is_bfs == 0){ $file_dir .= "\\";}else{$file_dir .= "/";}
  }
  elsif (substr($the_file, $the_index, 1) eq "\\" or substr($the_file, $the_index, 1) eq "/"){
    $file_name = substr($the_file, $the_index+1, length($the_file)-$the_index);
    $file_dir = substr($the_file, 0, $the_index+1);
  }
  else{
    $the_index--;
    my $init_index = $the_index;
    while (substr($the_file, $init_index, 1) ne "\\" and substr($the_file, $init_index, 1) ne "/"){
      $init_index--;

      if ($init_index < 0){
        last;
      }
    }

    $file_name = substr($the_file, $init_index+1, $the_index-$init_index);

    if ($init_index<0){
      $file_dir = $the_cwd;
      if ($is_bfs == 0){ $file_dir .= "\\";}else{$file_dir .= "/";}
    }
    else{
      $file_dir = substr($the_file, 0, $init_index+1);
    }
  }

  return ($file_name, $file_dir);
}

sub extract_word_tillspace{
  my ($the_line, $lline, $init_index) = @_;

  my $the_eol = 0;
  my $the_word = "";
  my $last_index = $init_index;

  while (substr($the_line, $last_index, 1) ne " "){
    $last_index++;

    if ($last_index > $lline){
      $the_eol = 1;
      last;
    }
  }

  $the_word = substr($the_line, $init_index, $last_index-$init_index);

  return ($the_word, $last_index);
}

sub extract_paths{
  my ($paths_file) = @_;

  my $paths_ok = 1;
  my $path_algo = " ";

  if (-e $paths_file){
    my $the_index = 0;
    my $init_index = 0;
    my $last_index = 0;

    if (open (my $file_header, '<:encoding(UTF-8)', $paths_file)){
      while (my $the_line = <$file_header>){
        chomp $the_line;
        #print "$the_line \n";

        $the_index = index ($the_line, "=");

        if ($the_index >= 0){
          $init_index = skip_spaces_forward($the_line, 0);
          $last_index = skip_spaces_backward($the_line, $the_index-1);
          my $the_solver = substr($the_line, $init_index, $last_index-$init_index+1);
          #print "the_solver: $the_solver \n";

          $init_index = skip_spaces_forward($the_line, $the_index+1);
          $last_index = skip_spaces_backward($the_line, length($the_line));
          my $the_path = substr($the_line, $init_index, $last_index-$init_index+1);
          #print "the_path: $the_path \n";

          if ($the_path =~ /[0-9a-zA-Z_]/ ){
            if ($the_solver eq "abc_algo"){
              $path_algo = $the_path;
            }
          }
          else{
            $paths_ok = 0;
          }
        }
      }

      if ($path_algo eq " "){
        $paths_ok = 0;
        print RED, "[ERROR] The path to the ABC algorithm could not be extracted from the $paths_file file! \n", RESET;
      }
      close ($file_header);
    }
    else{
      print RED, "[ERROR] Could not open the $paths_file file! \n", RESET;
    }
  }
  else{
    $paths_ok = 0;
    print RED, "[ERROR] Could not find the $paths_file file including paths to tools! \n", RESET;
  }

  return ($paths_ok, $path_algo);
}

sub generate_abc_script{
  my ($file_name, $file_dir) = @_;
  my $file_ver = $file_dir . $file_name . ".v";
  my $file_script = $file_dir . "abc_bench.script";

  open (my $fid_script, '>', $file_script);

  my $the_message = <<END_OF_MESSAGE;  
read_bench $file_net;
write_verilog $file_ver;
quit;
END_OF_MESSAGE
    printf $fid_script "%s \n", $the_message;

  close ($fid_script);

  return ($file_script, $file_ver);
}

sub file_generate_verilog{
  my ($file_name, $file_dir, $file_bench) = @_;
  print "[INFO] Converting the bench file to Verilog... \n";

  my $is_err = 0;
  my $key_num = 0;
  my $in_width = 0;
  my $sel_width = 0;
  my $out_width = 0;
  my $key_width = 0;
  my $key_avail = 0;
  my @key_arr = ();

  my ($path_ok, $abc_path) = extract_paths("paths.pl");
  if ($path_ok){
    my $fid_ver;

    #Convert operation names in lowercase to uppercase and extract input and output widths
    if (open(my $fid_bench, "<:encoding(utf8)", $file_bench)){
      my @all_lines = <$fid_bench>;
      close $fid_bench;
      
      open ($fid_bench, ">", $file_bench);
      for my $the_line (@all_lines){
        my $key_index = -1;
        my $key_index1 = index($the_line, "key=");
        my $key_index2 = index($the_line, "key =");
        my $key_index3 = index($the_line, "Key:");

        if ($key_index1 != -1){
          $key_index = $key_index1;
          $key_avail = 1;
          $key_index+=4;
        }
        elsif ($key_index2 != -1){
          $key_index = $key_index2;
          $key_avail = 1;
          $key_index+=5;
        }
        elsif ($key_index3 != -1){
          $key_index = $key_index3;
          $key_avail = 1;
          $key_index+=4;
        }

        my $op_index = index($the_line, "(");
        my $eql_index = index($the_line, "=");
        my $vdd_index = index($the_line, "vdd");
        my $gnd_index = index($the_line, "gnd");

        #print "the_line: $the_line \n";
        #print "key_index: $key_index eql_index: $eql_index \n";
        #sleep (1);

        if ($gnd_index != -1 or $vdd_index != -1){
          print "[ERROR] GND and VDD are not welcome by ABC! \n";
        }
        elsif ($key_index != -1){
          while (1){
            if (substr($the_line, $key_index, 1) eq "0"){
              $key_arr[$key_num] = 0;
              $key_num++;
            }
            elsif (substr($the_line, $key_index, 1) eq "1"){
              $key_arr[$key_num] = 1;
              $key_num++;
            }
            elsif (substr($the_line, $key_index, 1) eq "X" or substr($the_line, $key_index, 1) eq "x"){
              $key_arr[$key_num] = 0;
              $key_num++;
            }
            $key_index++;

            if ($key_index > length($the_line)){
              last;
            }
          }

          printf $fid_bench "%s", $the_line;
        }
        elsif ($eql_index != -1 and $op_index != -1){
          printf $fid_bench "%s ", substr($the_line, 0, $eql_index+1);
          $eql_index = skip_spaces_forward($the_line, $eql_index+1);
          while (1){
            my $the_char = substr($the_line, $eql_index, 1);
            if ($the_char eq "("){
              last;
            }
            else{
              if (ord($the_char)>=97){
                printf $fid_bench "%s", chr(ord($the_char)-32);
              }
              else{
                printf $fid_bench "%s", $the_char;
              }
            }
            $eql_index++;
          }
          printf $fid_bench "%s", substr($the_line, $eql_index, length($the_line)-$eql_index);
        }
        elsif ($eql_index != -1 and $op_index == -1){
          printf $fid_bench "%s", $the_line;
        }
        elsif ($key_index == -1 and $eql_index == -1){
          if (index($the_line, "INPUT") != -1){
            my $in_index = index($the_line, "x_in");
            my $sel_index = index($the_line, "sel_in");
            my $key_index = index($the_line, "keyinput");

            if ($sel_index != -1 or $in_index != -1 or $key_index != -1){
              my $the_width = 0;
              my $the_index = ($in_index != -1) ? $in_index+4 : ($sel_index != -1) ? $sel_index+6 : $key_index+8;
              
              while (1){
                my $the_char = substr($the_line, $the_index, 1);
                if (ord($the_char) >= 48 and ord($the_char) <= 57){
                  $the_width = 10*$the_width + $the_char;
                }
                else{
                  last;
                }
                $the_index++;
              }
              #print "the_line: $the_line the_width: $the_width \n";
              #sleep (1);

              if ($key_index != -1){
                if ($the_width > $key_width){
                  $key_width = $the_width;
                }
              }
              if ($sel_index != -1){
                if ($the_width > $sel_width){
                  $sel_width = $the_width;
                }
              }
              if ($in_index != -1){
                if ($the_width > $in_width){
                  $in_width = $the_width;
                }
              }
            }
          }
          elsif (index($the_line, "OUTPUT") != -1){
            my $out_index = index($the_line, "y_out");

            if ($out_index != -1){
              my $the_digit = 0;
              my $the_width = 0;
              my $the_index = $out_index+5;
              
              while (1){
                my $the_char = substr($the_line, $the_index, 1);
                if (ord($the_char) >= 48 and ord($the_char) <= 57){
                  $the_width = (10**$the_digit)*$the_width + $the_char;
                  $the_digit++;
                }
                else{
                  last;
                }
                $the_index++;
              }
              #print "the_line: $the_line the_width: $the_width \n";
              #sleep (1);

              if ($the_width > $out_width){
                $out_width = $the_width;
              }
            }
          }

          printf $fid_bench "%s", $the_line;
        }
      }

      if ($key_avail == 0){
        print "[INFO] Correct key is NOT available! \n";
      }
      else{
        $key_width++;
        print "[INFO] Correct key is available! \n";
      }

      if ($key_avail and $key_num != $key_width){
        print "[ERROR] Number of key inputs does NOT match! \n";
      }

      close ($fid_bench);

      #Run the ABC
      my ($file_script, $file_ver) = generate_abc_script($file_name, $file_dir);
      my $the_cmd = $abc_path . " -x -f " . $file_script;
      #print "the_cmd: $the_cmd  \n";
      system($the_cmd);
      
      #Change the module name in the Verilog file
      if (open (my $fid_ver, "<:encoding(utf8)", $file_ver)){
        my @all_lines = <$fid_ver>;
        close $fid_ver;
        
        my $mod_done = 0;
        open ($fid_ver, ">", $file_ver);
        for my $the_line (@all_lines) {
          if ($mod_done == 0){
            if (index($the_line, "module") != -1 ) {
              $mod_done = 1;
              printf $fid_ver "module %s ", $file_name;
              my $the_index = index($the_line, "(");
              printf $fid_ver "%s", substr($the_line, $the_index, length($the_line)-$the_index);
            }
            else{
              printf $fid_ver "%s", $the_line;
            }
          }
          else{
            printf $fid_ver "%s", $the_line;
          }

        }
        close ($fid_ver);
      }
      else{
        print "[ERROR] Could not open the $file_ver file! \n";
        $is_err = 1;
      }
    }
    else{
      print "[ERROR] Could not open the $file_bench file! \n";
      $is_err = 1;
    }
  }

  return ($is_err, $in_width, $sel_width, $out_width, $key_avail, $key_width, \@key_arr);
}


sub main_part{
  my ($file_name, $file_dir) = extract_file_name_directory($file_net);
  
  my ($is_err, $in_width, $sel_width, $out_width, $key_avail, $key_width, $key_arr_ref) = file_generate_verilog($file_name, $file_dir, $file_net);
}

