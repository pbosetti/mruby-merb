##
# MERB test

assert('MERB#scan') do
  merb = MERB.new "The value of $x is: <%= $x -%> (<)"
  result = merb.scan
  check  = [["The value of $x is: ", :text], ["= $x -", :ruby], [" (<)", :text]]
  assert_equal(check, result)
end

assert('MERB#source') do
  merb = MERB.new "The value of $x is: <%= $x -%> (<)"
  merb.scan
  result = merb.source
  check  = "$merbout = ''; $merbout.concat \"The value of $x is: \"; $merbout.concat(( $x  ).to_s); $merbout.concat \" (<)\"; "
  assert_equal(check, result)
end