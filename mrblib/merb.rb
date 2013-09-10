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
    result = self.run
    if out_file then
      File.unlink(out_file) if File.exist? out_file
      File.open(out_file, 'w') do |f|
        f.write result
      end
    end
    return result
  end
  
  def run
    $merbout = ''
    self.scan
    eval self.source
    return $merbout
  end
  
  def scan
    mode = :text
    chunk = ''
    raise RuntimeError, "Open and close tags must have the same length!" unless @tags[:open].length == @tags[:close].length
    tag_l = @tags[:open].length
    window = ' ' * tag_l
    @template.each_char do |c|
      next if c == "\r"
      window = window[1..-1] + c
      if window == @tags[:open] then
        @source << [chunk[0..-tag_l], :text]
        chunk = ''
        mode = :ruby
      elsif window == @tags[:close] then
        @source << [chunk[0..-tag_l], :ruby]
        chunk = ''
        mode = :text
      else
        chunk << c
      end
    end
    unless chunk.empty? then
      @source << [chunk, :text]
    end
  end
  
  def source
    result = "$merbout = ''; "
    after_output = false
    @source.each do |chunk, type|
      case type
      when :text
        if chunk.match(/^\n\s*$/) && after_output then
          result << "$merbout.concat %q(#{chunk}); "
        elsif ! after_output
          result << "$merbout.concat %q(#{chunk.gsub(/^\n\s*/, "")}); " 
        else
          result << "$merbout.concat %q(#{chunk}); " 
        end
      when :ruby
        if chunk[0] == '=' then
          if chunk[-1] == '-' then
            chunk = chunk[0..-2]
            after_output = false
          else
            after_output = true
          end
          result << "$merbout.concat((#{chunk[1..-1]}).to_s); "
        else
          after_output = false
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
