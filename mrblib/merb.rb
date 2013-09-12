# = MERB -- Ruby Templating
#
# Author:: Paolo Bosetti & Enrico Bertolazzi
# Copyright (c) 2013 Paolo BOSETTI
#
# You can redistribute it and/or modify it under the same terms as Ruby.

# 000000000000000000

class MERB

  attr_reader :commands
  attr_accessor :template
  
  def initialize(s = '')
    @tags     = { :open => '<%', :close => '%>' }
    @template = s
    @source   = []
    @commands = []
    @tokens   = []
    $merbout  = ''
  end
  
  def convert(in_file, out_file = nil)
    raise RuntimeError, "Open and close tags must have the same length!" unless @tags[:open].length == @tags[:close].length

    @template = File.open(in_file, 'r') { |f| f.read }    
    
    self.analyze

    if out_file then
      File.unlink(out_file) if File.exist? out_file
      File.open(out_file, 'w') { |f| f.write $merbout }
    end
    
    return $merbout
  end
  
  def analyze(tmpl = nil)
    if tmpl then
      @template = tmpl
    end
    return eval(self.source)
  end
  
  def source
    tokenize
    @commands = ["$merbout = ''"]
    last_tag  = [:null,:null,:null,:null]
    @tokens.each do |chunk, type|
      case type
      when :ruby_minus then
        @commands << "$merbout.concat((#{chunk}).to_s)"
      when :ruby then
        @commands << "$merbout.concat((#{chunk}).to_s)"
      when :ruby_cmd then
        @commands << chunk
      when :text, :text_nl
        chunk.gsub!( /\\/m, "\\\\" )
        chunk.gsub!( /\"/m, "\\\"" )
        chunk.gsub!( /\'/m, "\\\'" )
        chunk.gsub!( /\`/m, "\\\`" )
        chunk.gsub!( /\#/m, "\\\#" ) # filtra comandi #{}
        if type == :text then
          @commands << "$merbout.concat \"#{chunk}\"" 
        else
          @commands << "$merbout.concat \"#{chunk}\\n\" # :text_nl" 
        end
      when :blank_nl then
        unless [:ruby_minus, :ruby_cmd].include? last_tag[-1] then
          @commands << "$merbout.concat \"#{chunk}\\n\" # :blank_nl" 
        end
      when :blank then
        @commands << "$merbout.concat \"#{chunk}\" # :blank"
      end
      last_tag = last_tag[1..-1] << type
      
      # {:text_nl,:blank_nl} :blank :ruby_cmd :blank_nl --> {:text_nl,:blank_nl} :ruby_cmd
      # {:text_nl,:blank_nl} :ruby_cmd :blank_nl        --> {:text_nl,:blank_nl} :ruby_cmd
      if last_tag == [:text_nl,:blank,:ruby_cmd,:blank_nl] then
        last_tag = [:null,:null,:null,:blank_nl]
        @commands.pop
        tmp = @commands.pop
        @commands.pop
        @commands << tmp
      elsif last_tag == [:blank_nl,:blank,:ruby_cmd,:blank_nl] then
        last_tag = [:null,:null,:null,:blank_nl]
        @commands.pop
        tmp = @commands.pop
        @commands.pop
        @commands << tmp
      elsif last_tag[1..-1] == [:text_nl,:ruby_cmd,:blank_nl] then
        last_tag = [:null,:null,:null,:blank_nl]
        #@commands.pop
      elsif last_tag[1..-1] == [:blank_nl,:ruby_cmd,:blank_nl] then
        last_tag = [:null,:null,:null,:blank_nl]
        #@commands.pop
      end
    end
    return @commands.join("\n")
  end
  
  private
  def tokenize
    @tokens = []
    state  = [:text]
    chunk  = ''
    tag_l  = @tags[:open].length
    window = ' ' * tag_l
    # Start scanning
    # Normalize line endings to UNIX
    @template.gsub!( /\r\n/m, "\n" ) ;
    @template.gsub!( /\r/m, "\n" ) ;
    @template.each_char do |c|
      window = window[1..-1] + c # tiene finestra ultimi caratteri letti
      case state[-1]
      when :text then
        if window == @tags[:open] then
          # cerco di classificare il pezzo di testo
          chunk = chunk[0..-tag_l] # get rid of last char of closing tag
          if chunk.length > 0 then # se 2 tag consecutivi! niente testo
            if chunk =~ /^\s*$/ then
              @tokens << [chunk, :blank]
            else
              @tokens << [chunk, :text]
            end
          end
          chunk = ''
          state << :ruby
        elsif c == "\n"
          if chunk =~ /^\s*$/ then
            @tokens << [chunk, :blank_nl]
          else
            @tokens << [chunk, :text_nl]
          end
          chunk = ''
        else
          chunk << c
        end
      when :ruby then
        if window == @tags[:close] then
          chunk = chunk[0..-tag_l] # get rid of last char of closing tag
          if chunk[0] == '=' then
            if chunk[-1] == '-' then
              @tokens << [chunk[1..-2], :ruby_minus]
            else
              @tokens << [chunk[1..-1], :ruby]
            end
          else
            @tokens << [chunk[0..-1], :ruby_cmd]
          end
          chunk = ''
          state.pop
        else
          state << :ruby_string  if c == "\"" && window[-2] != "\\"
          state << :ruby_string2 if c == "\'" && window[-2] != "\\"
          chunk << c
        end
      when :ruby_string
        state.pop if window[-2..-1] != "\\\""
        chunk << c
      when :ruby_string2
        state.pop if window[-2..-1] != "\\\'"
        chunk << c
      end
    end
    unless chunk.empty? then
      @tokens << [chunk, :text]
    end
  end
end

# 000000000000000000

if __FILE__ == $0 then
  
  merb = MERB.new <<-EOF
The value of $x is: <%= $x %>, which is <%= $x > 0 ? "positive" : "negative" -%>.
Sequence
<% 5.times do |i| %>
  i = <%= i %>
<% end %>
End of transmission.
EOF
  $x = 20
  puts merb.analyze
  p merb.instance_variable_get :@tokens
  
  puts merb.convert("test.erb")
end
