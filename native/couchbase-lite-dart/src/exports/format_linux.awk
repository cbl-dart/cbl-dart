#! /usr/bin/env awk -f

BEGIN               { print "CBL_Dart {"; print "\tglobal:" }
/^[A-Za-z_]/        { print "\t\t" $0 ";"; next }
END                 { print "\tlocal:"; print "\t\t*;"; print "};" }
