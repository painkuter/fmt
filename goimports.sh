#!/bin/bash

FILESDIFFMASTER=$(git diff --name-only origin/master | grep -E '\.go')
PROJECTFOLDERNAME=$(basename `pwd`)
GOIMPORTS=$GOPATH/bin/goimports

goimports_sort_diff_master()
{
  git fetch;
  go get golang.org/x/tools/cmd/goimports;
	for f in $FILESDIFFMASTER; do
	    if grep -q -E '^// Code generated .* DO NOT EDIT\.$' $f; then
	      continue;
	    fi;
	    diff_file=$($GOIMPORTS -local $PROJECTFOLDERNAME -d $f);
        if [ "${#diff_file}" = 0 ]; then
        	newline_count=$(cat $f | perl -e 'while(<STDIN>){ $in .= $_ }; ($r) = $in =~ /(import \(.*?(\n\s*\n).*?\))/gms; if($r) { @n = $r =~ /(\s{3,})/g; print scalar(@n) } else { print 0 }');
        	if [ $newline_count -lt "3" ]; then
        		continue;
        	fi;
        fi;
        cat $f | perl -e 'while(<STDIN>){ $in .= $_ }; ($r) = $in =~ /(import \(.*?\))/gms; $r =~ s/\n\s*\n/\n/sgm; $in =~ s/import \(.*?\)/$r/gms; print $in' > $f.tmp; mv $f.tmp $f; \
	    $GOIMPORTS -local $PROJECTFOLDERNAME -w $f $f;
	    echo "File '$f' is changed!";
  	done
}

goimports_check_sort_diff_master()
{
  git fetch;
  go get golang.org/x/tools/cmd/goimports;
	is_exists_diff="";
	for f in $FILESDIFFMASTER; do
	    if grep -q -E '^// Code generated .* DO NOT EDIT\.$' $f; then
	      continue;
	    fi;
	    diff_file=$($GOIMPORTS -local $PROJECTFOLDERNAME -d $f);
		if [ "${#diff_file}" != 0 ]; then
		  	is_exists_diff="true";
		  	echo "File '$f' is needed to sort imports!";
		  	continue;
		fi;
		newline_count=$(cat $f | perl -e 'while(<STDIN>){ $in .= $_ }; ($r) = $in =~ /(import \(.*?(\n\s*\n).*?\))/gms; if($r) { @n = $r =~ /(\s{3,})/g; print scalar(@n) } else { print 0 }');
		if [ $newline_count -gt "2" ]; then
		  	is_exists_diff="true";
          	echo "File '$f' is needed to sort imports!";
		fi;
  	done;
  	if [ $is_exists_diff ]; then
  		exit 1;
  	else
  		echo "Not files to sort!";
  	fi
}

if [ "$1" = "check" ]; then
    goimports_check_sort_diff_master
fi

if [ "$1" = "sort" ]; then
    goimports_sort_diff_master
fi
