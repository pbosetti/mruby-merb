##
# MERB test

assert('MERB#source') do
  merb = MERB.new "The value of $x is: (<%= $x %>) \"<%= $x * 2 %>\""
  check = "MERB.out = ''\nMERB.out.concat \"The value of $x is: (\"\nMERB.out.concat(( $x ).to_s)\nMERB.out.concat \") \\\"\"\nMERB.out.concat(( $x * 2 ).to_s)\nMERB.out.concat \"\\\"\""
  assert_equal(check, merb.source)
end

