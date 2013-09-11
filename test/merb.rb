##
# MERB test

assert('MERB#source') do
  merb = MERB.new "The value of $x is: (<%= $x %>) \"<%= $x * 2 %>\""
  check = "$merbout = ''\n$merbout.concat \"The value of $x is: (\"\n$merbout.concat(( $x ).to_s)\n$merbout.concat \") \\\"\"\n$merbout.concat(( $x * 2 ).to_s)\n$merbout.concat \"\\\"\""
  assert_equal(check, merb.source)
end

