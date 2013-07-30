# = MERB -- Ruby Templating
#
# Author:: Paolo Bosetti
# Copyright (c) 2013 Paolo BOSETTI
#
# You can redistribute it and/or modify it under the same terms as Ruby.


class MERB
  attr_accessor :template, :tags
  attr_reader :merbout
  def initialize(s = '')
    @tags     = {open: '<%', close: '%>'}
    @template = s
    @source   = []
    $merbout  = ''
  end
  
  def convert(in_file, out_file = nil)
    File.open(in_file, 'r') do |f|
      @template = f.read
    end
    if out_file then
      # Dunno why it does not work
      File.open(out_file, 'w+') do |f|
        f.write self.run
      end
    else
      return self.run
    end
  end
  
  def run
    $merbout = ''
    self.scan
    eval self.source
    return $merbout
  end
  
  def scan
    mode = :text
    i = 0
    park = ''
    chunk = ''
    @template.each_char do |c|
      if park == @tags[:open] then
        @source << [chunk, :text]
        chunk = ''
        mode = :ruby; park = ''; i = 0
      elsif park == @tags[:close] then
        @source << [chunk, :ruby]
        chunk = ''
        mode = :text; park = ''; i = 0
      end
        
      if c == @tags[:open][i] then
        park << c; i += 1; next
      elsif c == @tags[:close][i] then
        park << c; i += 1; next
      else
        chunk << park; park = ''; i = 0
      end
      chunk << c
    end
    unless chunk.empty? then
      @source << [chunk, :text]
    end
  end
  
  def source
    result = "$merbout = ''; "
    @source.each do |chunk, type|
      case type
      when :text
        if chunk[0] == "\n" then
          chunk = chunk[1..-1]
        end
        result << "$merbout.concat \"#{chunk}\"; " 
      when :ruby
        if chunk[-1] == '-' then
          chunk = chunk[0..-2]; nl = ''
        else
          nl = ' + "\n"'
        end
        if chunk[0] == '=' then
          result << "$merbout.concat((#{chunk[1..-1]} ).to_s#{nl}); "
        else
          result << chunk.chomp + ";\n"
        end
      end
    end
    return result
  end
end



if __FILE__ == $0 then
  
  merb = MERB.new <<-EOF
The value of $x is: <%= $x -%> which is <%= $x > 0 ? "positive" : "negative" -%>.
Sequence<:%
<% 5.times do |i| %>
  i = <%= i %>
<% end %>
End of transmission.
EOF
  $x = 20
  merb.scan
  puts merb.run
  
  puts merb.convert("test.erb")
end