#!/usr/bin/perl

use strict;
use POSIX();
use warnings;
use Cwd qw(cwd); 
#use diagnostics;
#use Math::Matrix;
use Storable qw(dclone);
use Time::HiRes qw(time);
use Term::ANSIColor qw(:constants);

my $arg_ok = 1;
my $arg_cnt = 0;

my $verb_val = 0;
my $lib_file = "";
my $ver_file = "";
my $out_file = "";

while (1){
  if (defined $ARGV[$arg_cnt]){
    if ($ARGV[$arg_cnt] eq "-h" or $ARGV[$arg_cnt] eq "-help"){
      $arg_ok = 0;
    }
    else {
      if (index($ARGV[$arg_cnt], "-v=") != -1){
        $ver_file = substr($ARGV[$arg_cnt], 3, length($ARGV[$arg_cnt])-3);
      }
      elsif (index($ARGV[$arg_cnt], "-l=") != -1){
        $lib_file = substr($ARGV[$arg_cnt], 3, length($ARGV[$arg_cnt])-3);
      }
      elsif (index($ARGV[$arg_cnt], "-o=") != -1){
        $out_file = substr($ARGV[$arg_cnt], 3, length($ARGV[$arg_cnt])-3);
      }
      elsif (index($ARGV[$arg_cnt], "-verb=") != -1){
        $verb_val = substr($ARGV[$arg_cnt], 6, length($ARGV[$arg_cnt])-6)+0.0;
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
else{
  if ($ver_file eq "" or $lib_file eq ""){
    help_part();
  }
  else{
    main_part();
  }
}

sub help_part{
  print "########################################################################################################## \n";
  print "# Usage:       perl ver2bench.pl -v=<FileName> -l=<FileName> -o=<FileName> -verb=<int>                   # \n";
  print "# v:           Name of the Verilog file including the gate-level netlist                                 # \n";
  print "# l:           Name of the library file including the gate functions                                     # \n";
  print "# o:           Name of the output file by default it is extracted from the Verilog file                  # \n";
  print "# verb:        Level of verbosity by default it is 0 and the comments in the bench file are suppresed    # \n";
  print "# Description: This code converts the gate-level netlist in Verilog to the bench format                  # \n";
  print "# Notes:       The function of a gate given in the library must not include any spaces                   # \n";
  print "########################################################################################################## \n";
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

sub print_array{
  my ($the_label, $the_cnt, $the_arr_ref) = @_;

  print "$the_label: ";
  for (my $i = 0; $i < $the_cnt; $i++){
    print "$the_arr_ref->[$i] ";
  }
  print "\n";
}

sub print_matrix{
  my ($the_label, $row_num, $col_num, $the_matrix_ref) = @_;

  print "$the_label: \n";
  for (my $i = 0; $i < $row_num; $i++){
    for (my $j = 0; $j < $col_num; $j++){
      print "$the_matrix_ref->[$i][$j] ";
    }
    print "\n";
  }
}

sub print_oper{
  my ($oper_cnt, $oper_mat_ref) = @_;

  print "Operation Matrix \n";
  for (my $i=0; $i<$oper_cnt; $i++){
    print "$oper_mat_ref->[$i][1] = $oper_mat_ref->[$i][0](";
    for (my $j=0; $j<$oper_mat_ref->[$i][2]; $j++){
      if ($j == $oper_mat_ref->[$i][2]-1){
        print "$oper_mat_ref->[$i][$j+3]) \n";
      }
      else{
        print "$oper_mat_ref->[$i][$j+3], ";
      }
    }
  }
}

sub where_is_inside_vararr{
  my ($the_str, $var_cnt, $col_index, $var_arr_ref) = @_;

  my $the_index = -1;

  for (my $i=0; $i<$var_cnt; $i++){
    if ($the_str eq $var_arr_ref->[$i][$col_index]){
      $the_index = $i;
      last;
    }
  }

  return ($the_index);
}

sub check_paranthesis_valid{
  my ($par_cnt, $par_arr_ref) = @_;

  my $the_result = 1;

  for (my $i=0; $i<$par_cnt; $i++){
    if ($par_arr_ref->[$i][1] == -1){
      $the_result = 0;
      last;
    }
  }

  return ($the_result);
}

sub format_varname{
  my ($the_var) = @_;

  my $the_char;
  my $the_index = 0;
  my $new_var = "";
  my $lvar = length($the_var);

  while(1){
    $the_char = substr($the_var, $the_index, 1);
    if ($the_char ne "[" and $the_char ne "]"){
      $new_var .= $the_char;
    }

    $the_index++;
    if ($the_index > $lvar){
      last;
    }
  }

  return ($new_var);
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

sub extract_gate_func{
  my ($the_gate) = @_;

  my $gate_out = "";
  my $gate_type = "";
  my $gate_func = "";

  my $is_err = 0;
  my $the_index = 0;
  my $init_index = 0;
  my $last_index = 0;

  if (open (my $fid_lib, '<:encoding(UTF-8)', $lib_file)){
    while (my $the_line = <$fid_lib>){
      chomp $the_line;
      #print "$the_line \n";
      my $lline = length($the_line);

      $init_index = skip_spaces_forward($the_line, 0);
      $last_index = $init_index;
      while (substr($the_line, $last_index, 1) ne " "){
        $last_index++;

        if ($last_index > $lline){
          $is_err = 1;
          last;
        }
      }

      if ($is_err == 0){
        $gate_type = substr($the_line, $init_index, $last_index-$init_index);
        
        $init_index = skip_spaces_forward($the_line, $last_index);
        $last_index = $init_index;
        while (substr($the_line, $last_index, 1) ne " "){
          $last_index++;

          if ($last_index > $lline){
            $is_err = 1;
            last;
          }
        }

        if ($is_err == 0){
          my $gate_label = substr($the_line, $init_index, $last_index-$init_index);
    
          if ($the_gate eq $gate_label){
            $the_index = index($the_line, "=");
            
            if ($the_index != -1){
              #Gate output
              $last_index = skip_spaces_backward($the_line, $the_index-1);
              $init_index = $last_index;
              while (substr($the_line, $init_index, 1) ne " "){
                $init_index--;

                if ($init_index < 0){
                  print "[ERROR] Could not find the output of the $the_gate gate! \n";
                  $is_err = 1;
                  last;
                }
              }

              if ($is_err == 0){
                $gate_out = substr($the_line, $init_index+1, $last_index-$init_index);

                #Gate Function
                $init_index = skip_spaces_forward($the_line, $the_index+1);
                $last_index = $init_index;
                while (substr($the_line, $last_index, 1) ne ";"){
                  $last_index++;

                  if ($last_index > $lline){
                    print "[ERROR] Could not find the function of the $the_gate gate! \n";
                    $is_err = 1;
                    last;
                  }
                }

                $gate_func = substr($the_line, $init_index, $last_index-$init_index);
                last;
              }
            }
          }
        }
      }
    }

    close ($fid_lib);
  }
  else{
    print "[ERROR] Could not open the $lib_file library! \n";
  }

  return ($is_err, $gate_type, $gate_out, $gate_func);
}

sub extract_oper{
  my ($init_index, $last_index, $gate_func) = @_;

  #print "init_index: $init_index last_index: $last_index \n";

  my $is_err = 0;
  my @in_arr = ();
  my $in_cnt = 0;
  my $in_var = "";
  my $the_oper = "";
  my $the_char = "";
  
  for (my $the_index=$init_index; $the_index<$last_index; $the_index++){
    $the_char = substr($gate_func, $the_index, 1);

    if ($the_char eq "*"){
      if ($the_oper eq ""){
        $the_oper = "AND";
      }
      else{
        if ($the_oper ne "AND"){
          print "[ERROR] There are multiple operations in gate function $gate_func \n";
          #sleep (100);
          $is_err = 1;
          last;
        }
      }
      $in_arr[$in_cnt] = $in_var;
      $in_cnt++;
      $in_var = "";
    }
    elsif ($the_char eq "+"){
      if ($the_oper eq ""){
        $the_oper = "OR";
      }
      else{
        if ($the_oper ne "OR"){
          print "[ERROR] There are multiple operations in gate function $gate_func \n";
          #sleep (100);
          $is_err = 1;
          last;
        }
      }
      $in_arr[$in_cnt] = $in_var;
      $in_cnt++;
      $in_var = "";
    }
    elsif ($the_char eq "^"){
      if ($the_oper eq ""){
        $the_oper = "XOR";
      }
      else{
        if ($the_oper ne "XOR"){
          print "[ERROR] There are multiple operations in gate function $gate_func \n";
          #sleep (100);
          $is_err = 1;
          last;
        }
      }
      $in_arr[$in_cnt] = $in_var;
      $in_cnt++;
      $in_var = "";
    }
    else{
      $in_var .= $the_char;
    }
  }

  if ($is_err == 0){
    $in_arr[$in_cnt] = $in_var;
    $in_cnt++;
  }

  return ($is_err, $the_oper, $in_cnt, \@in_arr);
}

sub implement_gate_function{
  my ($gate_out, $gate_func) = @_;

  my $oper_cnt = 0;
  my @oper_mat = ();

  my $the_end = 0;
  my $aux_cnt = 0;
  my $the_char = "";
  my $the_index = 0;
  my $init_index = 0;
  my $last_index = 0;

  my $iter_num = 0;
  my $lfunc = length($gate_func);

  while (1){
    my $is_oper = 0;  #Denotes the function includes an and (*), or(+), xor(^) operator
    my $inv_eff = 0;  #Denotes the function includes an inverse (!) operator

    #Check for an inverse
    $the_end = 0;
    $the_index = 0;
    while ($the_end == 0){
      $the_char = substr($gate_func, $the_index, 1);
      if ($the_char eq "!"){
        $the_index++;
        $the_char = substr($gate_func, $the_index, 1);
        if ($the_char ne "("){
          my $new_gf = substr($gate_func, 0, $the_index-1);
          $last_index = $the_index;
          while (1){
            $the_char = substr($gate_func, $last_index, 1);
            if ($the_char eq ")"){
              last;
            }
            elsif ($the_char eq "*" or $the_char eq "+" or $the_char eq "^"){
              last;
            }
            else{
              $last_index++;
              if ($last_index > $lfunc){
                $last_index--;
                $the_end = 1;
                last;
              }
            }
          }
          my $inv_in = substr($gate_func, $the_index, $last_index-$the_index);
          #print "inv_in: $inv_in \n";

          my $inv_out = "aux" . $aux_cnt;
          my $linvout = length($inv_out);
          $aux_cnt++;
          
          $oper_mat[$oper_cnt][0] = "NOT";
          $oper_mat[$oper_cnt][1] = $inv_out;
          $oper_mat[$oper_cnt][2] = 1;
          $oper_mat[$oper_cnt][3] = $inv_in;
          $oper_cnt++;

          $new_gf .= $inv_out . substr($gate_func, $last_index, $lfunc-$last_index);
          $gate_func = $new_gf;
          $lfunc = length($gate_func);
          $the_index += $linvout - 1;

          $inv_eff = 1;
          #print "gate_func: $gate_func \n";
        }
      }
      else{
        if ($the_char eq "*" or $the_char eq "+" or $the_char eq "^"){
          $is_oper = 1;
        }

        $the_index++;
        if ($the_index > $lfunc){
          $the_end = 1;
        }
      }
    }

    #Numerate the paranthesis
    my $par_valid = -1;
    my $par_cnt = 0;
    my @par_arr = ();
    
    $the_index = 0;
    while (1){
      if (substr($gate_func, $the_index, 1) eq "("){
        $par_arr[$par_cnt][0] = $the_index;
        $par_arr[$par_cnt][1] = -1;
        $par_cnt++;
      }
      elsif (substr($gate_func, $the_index, 1) eq ")"){
        $par_valid = 0;
        for (my $i=$par_cnt-1; $i>=0; $i--){
          if ($par_arr[$i][1] == -1){
            $par_arr[$i][1] = $the_index;
            $par_valid = 1;
            last;
          }
        }
        if ($par_valid == 0){
          print "[ERROR] The paranthesis in gate function $gate_func is INVALID! \n";
          last;
        }
      }

      $the_index++;
      if ($the_index > $lfunc){
        last;
      }
    }

    if ($par_valid){
      if (check_paranthesis_valid($par_cnt, \@par_arr) == 0){
        print "[ERROR] The paranthesis in gate function $gate_func is INVALID! \n";
        last;
      }
      else{
        #Evaluate a single operation
        if ($par_cnt == 0){
          #print "iter_num: $iter_num, inv_eff: $inv_eff, is_oper: $is_oper \n";
          # BUFFER
          if ($iter_num == 0 and $inv_eff == 0 and $is_oper == 0){
            $oper_mat[$oper_cnt][0] = "BUF";
            $oper_mat[$oper_cnt][1] = $gate_out;
            $oper_mat[$oper_cnt][2] = 1;
            $oper_mat[$oper_cnt][3] = $gate_func;
            $oper_cnt++;
          }
          # A SINGLE INVERTER or BUFFER - needs an update at the output
          elsif ($is_oper == 0){
            $oper_mat[$oper_cnt-1][1] = $gate_out;
          }
          # AN OPERATION
          elsif ($is_oper){
            my ($is_err, $the_oper, $in_cnt, $in_arr_ref) = extract_oper(0, $lfunc, $gate_func);
            if ($is_err == 0){
              #print "gate_func: $gate_func \n";
              #print_array("in_arr", $in_cnt, $in_arr_ref);

              $oper_mat[$oper_cnt][0] = $the_oper;
              $oper_mat[$oper_cnt][1] = $gate_out;
              $oper_mat[$oper_cnt][2] = $in_cnt;
              for (my $i=0; $i<$in_cnt; $i++){
                $oper_mat[$oper_cnt][$i+3] = $in_arr_ref->[$i];
              }
              $oper_cnt++;
            }
          }

          last;
        }
        #Evaluate an operation inside paranthesis
        else{
          $iter_num++;
          my ($is_err, $the_oper, $in_cnt, $in_arr_ref) = extract_oper($par_arr[$par_cnt-1][0]+1, $par_arr[$par_cnt-1][1], $gate_func);
          if ($is_err == 0){
            #print "gate_func: $gate_func \n";
            #print_array("in_arr", $in_cnt, $in_arr_ref);

            # An operation
            if ($in_cnt > 1){
              my $new_gf = substr($gate_func, 0, $par_arr[$par_cnt-1][0]);
              my $oper_out = "aux" . $aux_cnt;
              $aux_cnt++;

              $oper_mat[$oper_cnt][0] = $the_oper;
              $oper_mat[$oper_cnt][1] = $oper_out;
              $oper_mat[$oper_cnt][2] = $in_cnt;
              for (my $i=0; $i<$in_cnt; $i++){
                $oper_mat[$oper_cnt][$i+3] = $in_arr_ref->[$i];
              }
              $oper_cnt++; 

              $new_gf .= $oper_out . substr($gate_func, $par_arr[$par_cnt-1][1]+1, $lfunc-$par_arr[$par_cnt-1][1]-1);
              $gate_func = $new_gf;
              $lfunc = length($gate_func);
              #print "gate_func: $gate_func \n";
            }
            # A signal
            else{
              my $new_gf = substr($gate_func, 0, $par_arr[$par_cnt-1][0]);
              $new_gf .= $in_arr_ref->[0] . substr($gate_func, $par_arr[$par_cnt-1][1]+1, $lfunc-$par_arr[$par_cnt-1][1]-1);
              $gate_func = $new_gf;
              $lfunc = length($gate_func);
              #print "gate_func: $gate_func \n";
            }
          }
        }
      }
    }
    else{
      last;
    }
  }

  return ($oper_cnt, \@oper_mat);
}

sub whereis_inside_gatearr{
  my ($the_gate, $gate_cnt, $gate_arr_ref) = @_;

  my $gate_index = -1;

  for (my $i=0; $i<$gate_cnt; $i++){
    if ($gate_arr_ref->[$i][0] eq $the_gate){
      $gate_index = $i;
      last;
    }
  }

  return ($gate_index);
}

sub main_part{
  my $gate_cnt = 0;
  my $gate_num = 0;
  my $line_cnt = 0;
  my $wire_cnt = 0;
  my $true_var = 0;
  my $oper_cnt = 0;
  my @gate_arr = ();
  my $false_var = 0;
  my $an_input = "";
  my $the_word = "";
  my $the_index = 0;
  my $init_index = 0;
  my $last_index = 0;
  my $oper_mat_ref = 0;

  my $initial_time = time();

  #Extract the directory and name of the Verilog file
  if ($out_file eq ""){
    my ($file_name, $file_dir) = extract_file_name_directory($ver_file);
    $out_file = $file_dir . $file_name . ".bench";
  }

  #Open the out file
  open (my $fid_out, '>', $out_file);

  #Read the verilog gate-level netlist
  if (open (my $fid_ver, '<:encoding(UTF-8)', $ver_file)){
    print "[INFO] Converting the Verilog file to bench format... \n";
    while (my $the_line = <$fid_ver>){
      $line_cnt++;
      chomp $the_line;
      #print "$the_line \n";
      my $lline = length($the_line);
      
      #Find the first word on the line
      $init_index = skip_spaces_forward($the_line, 0);
      ($the_word, $last_index) = extract_word_tillspace($the_line, $lline, $init_index);
      #print "the_word: $the_word \n";
      
      #Empty line
      if ($the_word eq "" or $the_word eq " "){
      }
      #No relevant data in the line starting with module or wire
      elsif ($the_word eq "module" or $the_word eq "wire"){
        while (index($the_line, ";") == -1){
          $the_line = <$fid_ver>;
          chomp($the_line);
          $line_cnt++;
        }
      }
      #endmodule word ends the conversion
      elsif ($the_word eq "endmodule"){
        last;
      }
      #Comments are skipped except the one indicating the secret key
      elsif ($the_word eq "//"){
        $the_index = index($the_line, "key:");
        if ($the_index != -1){
          $the_index=skip_spaces_forward($the_line, $the_index+4);
          my $key_str = substr($the_line, $the_index, $lline-$the_index);
          printf $fid_out "#key=%s \n", $key_str;
          if (index($key_str, "1") != -1 or index($key_str, "0") != -1){
            print "[INFO] Secret key is available! \n";
          }
        }
      }
      #Declaration of inputs/outputs
      elsif ($the_word eq "input" or $the_word eq "output"){
        #print "the_line: $the_line \n";

        #Find the bitwdith of the input
        my $the_msb = 0;
        my $the_lsb = 0;
        my $the_width = 1;
        my $lsb_index = index($the_line, "[");
        if ($lsb_index != -1){
          $init_index = skip_spaces_forward($the_line, $lsb_index+1);

          $last_index = $init_index;
          while (substr($the_line, $last_index, 1) ne ":"){
            $last_index++;
          }
          $the_msb = substr($the_line, $init_index, $last_index-$init_index);

          $init_index = skip_spaces_forward($the_line, $last_index+1);
          $last_index = $init_index;
          while (substr($the_line, $last_index, 1) ne "]"){
            $last_index++;
          }
          $the_lsb = substr($the_line, $init_index, $last_index-$init_index);

          $the_width = $the_msb-$the_lsb+1;
          #print "the_width: $the_width \n";
        }

        #Extract the names of inputs/outputs
        my $the_eol = 0;
        while (1){
          $init_index = skip_spaces_forward($the_line, $last_index+1);
          $last_index = $init_index;
          while (substr($the_line, $last_index, 1) ne "," and substr($the_line, $last_index, 1) ne ";"){
            $last_index++;
            
            if ($last_index > $lline){
              $the_eol = 1;
              last;
            }
          }

          if ($the_eol){
            $line_cnt++;
            $the_eol = 0;
            $last_index = -1;
            $the_line = <$fid_ver>;
            chomp($the_line);
            $lline = length($the_line);  
          }
          else{
            my $io_name = substr($the_line, $init_index, $last_index-$init_index);
            #print "io_name: $io_name \n";
           
            #Add the inputs/outputs to the bench file
            if ($the_msb > $the_lsb){
              for (my $i=$the_lsb; $i<=$the_msb; $i++){
                if ($the_word eq "input"){
                  $an_input = $io_name . $i;
                  printf $fid_out "INPUT(%s%d) \n", $io_name, $i;
                }
                else{
                  printf $fid_out "OUTPUT(%s%d) \n", $io_name, $i;
                }
              }
            }
            else{
              if ($the_word eq "input"){
                #Do not include the clock and reset variables
                #if ($io_name ne $clk_str and $io_name ne $rst_str){
                  $an_input = $io_name;
                  printf $fid_out "INPUT(%s) \n", $io_name;
                #}
              }
              else{
                printf $fid_out "OUTPUT(%s) \n", $io_name;
              }
            }
            
            if (substr($the_line, $last_index, 1) eq ";"){
              last;
            }
          }
        }
      }
      #Replace the assign with a buffer
      elsif ($the_word eq "assign"){
        #print "the_line: $the_line \n";
        $last_index = skip_spaces_forward($the_line, $last_index);

        my $buf_err = 0;
        my $buf_out = "";
        while (1){
          my $the_char = substr($the_line, $last_index, 1);

          if ($the_char eq "="){
            last;
          }
          else{
            if ($the_char ne "[" and $the_char ne "]" and $the_char ne " "){
              $buf_out .= $the_char;
            }
            $last_index++;
          }

          if ($last_index > $lline){
            print "[ERROR] Buffer should have one input and one output \n";
            $buf_err = 1;
            last;
          }
        }

        if (!$buf_err){
          #print "buf_out: $buf_out \n";
          $last_index = skip_spaces_forward($the_line, $last_index+1);

          my $buf_in = "";
          while (1){
            my $the_char = substr($the_line, $last_index, 1);

            if ($the_char eq " " or $the_char eq "\n"){
              last;
            }
            else{
              if ($the_char ne "[" and $the_char ne "]" and $the_char ne " " and $the_char ne ";"){
                $buf_in .= $the_char;
              }
              $last_index++;
            }

            if ($last_index > $lline){
              last;
            }
          }

          if ($buf_in eq ""){
            print "[ERROR] Buffer should have one input and one output! \n";
          }
          elsif ($buf_in eq "1'b0"){
            if (!$false_var){
              printf $fid_out "falsevar = xor(%s, %s) \n", $an_input, $an_input;
              $false_var = 1;
            }
            printf $fid_out "%s = buf(falsevar) \n", $buf_out;
          }
          elsif ($buf_in eq "1'b1"){
            if (!$true_var){
              printf $fid_out "truevar = xnor(%s, %s) \n", $an_input, $an_input;
              $true_var = 1;
            }
            printf $fid_out "%s = inv(truevar) \n", $buf_out;
          }
          else{
            printf $fid_out "%s = buf(%s) \n", $buf_out, $buf_in;
          }
        }
      }
      #Convert the gates in the netlist based on their functions given in the library 
      else{
        my ($is_gate_err, $gate_type, $gate_out, $gate_func) = extract_gate_func($the_word);
        if ($is_gate_err == 0){
          if ($gate_func eq ""){
            print "[ERROR] The gate $the_word is NOT in the library! \n";
          }
          else{
            $gate_num++;

            my $gate_index = whereis_inside_gatearr($the_word, $gate_cnt, \@gate_arr);
            if ($gate_index == -1){
              #print "gate_type: $gate_type gate_out: $gate_out gate_func: $gate_func \n";
              ($oper_cnt, $oper_mat_ref) = implement_gate_function($gate_out, $gate_func);
              #print_oper($oper_cnt, $oper_mat_ref);
              $gate_arr[$gate_cnt][0] = $the_word;
              $gate_arr[$gate_cnt][1] = $oper_cnt;
              $gate_arr[$gate_cnt][2] = $oper_mat_ref;
            }
            else{
              $oper_cnt = $gate_arr[$gate_cnt][1];
              $oper_mat_ref = $gate_arr[$gate_cnt][2];
            }
            
            my $the_end = 0;
            my $var_cnt = 0;
            my @var_arr = ();
            my $the_char = "";
            
            $init_index = 0;
            while ($the_end == 0){
              my $dot_found = 0;
              while (1){
                $the_char = substr($the_line, $init_index, 1);

                if ($the_char eq "."){
                  $dot_found = 1;
                  last;
                }
                elsif ($the_char eq ";"){
                  $the_end = 1;
                  last;
                }
                else{
                  $init_index++;
                  if ($init_index > $lline){
                    $line_cnt++;
                    $init_index = 0;
                    $the_line = <$fid_ver>;
                    chomp($the_line);
                    $lline = length($the_line);
                    #print "the_line: $the_line \n";
                  }
                }
              }
              if ($dot_found){
                $init_index = skip_spaces_forward($the_line, $init_index+1);
                $last_index = $init_index;
                while (1){
                  $the_char = substr($the_line, $last_index, 1);
                  if ($the_char eq " " or $the_char eq "("){
                    last;
                  }
                  else{
                    $last_index++;
                    if ($last_index > $lline){
                      last;
                    }
                  }
                }

                my $gate_var = substr($the_line, $init_index, $last_index-$init_index);
                #print "gate_var: $gate_var \n";

                $init_index = $last_index-1;
                while (1){
                  $the_char = substr($the_line, $init_index, 1);
                  if ($the_char eq "("){
                    last;
                  }
                  else{
                    $init_index++;
                    if ($init_index > $lline){
                      $line_cnt++;
                      $init_index = 0;
                      $the_line = <$fid_ver>;
                      chomp($the_line);
                      $lline = length($the_line);
                      #print "the_line: $the_line \n";
                    }
                  }
                }

                $init_index = skip_spaces_forward($the_line, $init_index+1);
                $last_index = $init_index;
                while (1){
                  $the_char = substr($the_line, $last_index, 1);
                  if ($the_char eq " " or $the_char eq ")"){
                    last;
                  }
                  else{
                    $last_index++;
                    if ($last_index > $lline){
                      last;
                    }
                  }
                }

                my $des_var = substr($the_line, $init_index, $last_index-$init_index);
                $des_var = format_varname($des_var);
                #print "des_var: $des_var \n";

                if ($des_var eq "1'b0"){
                  print "[INFO] Constant-0 has just been observed on a gate input!\n";
                  if (!$false_var){
                    printf $fid_out "falsevar = xor(%s, %s) \n", $an_input, $an_input;
                    $false_var = 1;
                  }
                  $des_var = "falsevar";
                }
                elsif ($des_var eq "1'b1"){
                  print "[INFO] Constant-1 has just been observed on a gate input!\n";
                  if (!$true_var){
                    printf $fid_out "truevar = xnor(%s, %s) \n", $an_input, $an_input;
                    $true_var = 1;
                  }
                  $des_var = "truevar";
                }

                $var_arr[$var_cnt][0] = $gate_var;
                $var_arr[$var_cnt][1] = $des_var;
                $var_cnt++;
              }
            }
            #print_matrix("var_arr", $var_cnt, 2, \@var_arr);

            #Write the operations in the bench file
            if ($verb_val){printf $fid_out "# Line Number in the Verilog File: %d \n", $line_cnt;}
            if ($verb_val){printf $fid_out "# Gate function in the Library File: %s \n", $gate_func;}

            if ($gate_type eq "GATE"){
              my @aux_arr = ();

              for (my $op_index=0; $op_index<$oper_cnt; $op_index++){
                my $oper_str = "";
                
                # Add the operation output
                my $oper_out = $oper_mat_ref->[$op_index][1];
                my $loo = length($oper_out);
                #print "oper_out: $oper_out loo: $loo \n";
                if (index($oper_out, "aux") != -1){
                  my $aux_index = substr($oper_out, 3, $loo-3) + 0.0;
                  $aux_arr[$aux_index] = $wire_cnt;
                  $oper_str .= "wire" . $wire_cnt . " = ";
                  $wire_cnt++;
                }
                else{
                  ($the_index) = where_is_inside_vararr($oper_out, $var_cnt, 0, \@var_arr);
                  if ($the_index != -1){
                    $oper_str .= $var_arr[$the_index][1] . " = ";
                  }
                  else{
                    print "[ERROR] Could not find the $oper_out in the gate declaration at line $line_cnt! \n";
                  }
                }

                # Add the operation type
                $oper_str .= $oper_mat_ref->[$op_index][0] . "(";

                # Add the operation inputs
                for (my $in_index=0; $in_index<$oper_mat_ref->[$op_index][2]; $in_index++){
                  my $oper_in = $oper_mat_ref->[$op_index][$in_index+3];
                  my $loi = length($oper_in);
                  #print "oper_in: $oper_in loi: $loi \n";
                  if (index($oper_in, "aux") != -1){
                    #print "loi: $loi, oper_in $oper_in \n";
                    my $aux_index = substr($oper_in, 3, $loi-3) + 0.0;
                    $oper_str .= "wire" . $aux_arr[$aux_index];
                  }
                  else{
                    ($the_index) = where_is_inside_vararr($oper_in, $var_cnt, 0, \@var_arr);
                    if ($the_index != -1){
                      $oper_str .= $var_arr[$the_index][1];
                    }
                    else{
                      print "[ERROR] Could not find the $oper_out in the gate declaration at line $line_cnt! \n";
                    }
                  }
                  if ($in_index == $oper_mat_ref->[$op_index][2]-1){
                    $oper_str .= ")";
                  }
                  else{
                    $oper_str .= ",";
                  }
                }
                #print "oper_str: $oper_str \n";
                printf $fid_out "%s \n", $oper_str;
              }
            }
            elsif ($gate_type eq "LATCH"){
              my $oper_str = "";
              ($the_index) = where_is_inside_vararr("Q", $var_cnt, 0, \@var_arr);
              if ($the_index != -1){
                $oper_str .= $var_arr[$the_index][1] . " = DFF(";
              }
              else{
                print "[ERROR] Could not find the Q in the gate declaration at line $line_cnt! \n";
              }
              ($the_index) = where_is_inside_vararr("D", $var_cnt, 0, \@var_arr);
              if ($the_index != -1){
                $oper_str .= $var_arr[$the_index][1] . ")";
              }
              else{
                print "[ERROR] Could not find the D in the gate declaration at line $line_cnt! \n";
              }
              #print "oper_str: $oper_str \n";
              printf $fid_out "%s \n", $oper_str;
            }
            else{
              print "[ERROR] Given gate type $gate_type is NOT our list! \n";
            }
          }
        }
        else{
          while (index($the_line, ";") == -1){
            $the_line = <$fid_ver>;
            chomp($the_line);
            $line_cnt++;
          }
          print "[ERROR] The gate $the_word is not given in the $lib_file library! \n";
        }
      }
    }

    print "[INFO] Number of gates processed: $gate_num \n";
    my $last_time = time() - $initial_time;
    printf "[INFO] CPU time: %.2f \n", $last_time;
    close ($fid_ver);
  }
  else{
    print "[ERROR] Could not open the $ver_file file! \n";
  }
  
  close ($fid_out);
}
