# = MERB -- Ruby Templating
#
# Author:: Paolo Bosetti & Enrico Bertolazzi
# Copyright (c) 2013 Paolo BOSETTI
#
# You can redistribute it and/or modify it under the same terms as Ruby.

# 000000000000000000

class MERB

  attr_reader :commands

  def initialize(s = '')
    @tags     = { :open => '<%', :close => '%>' }
    @template = s
    @source   = []
    $merbout  = ''
  end
  
  def convert(in_file, out_file = nil)
    File.open(in_file, 'r') do |f|
      @template = f.read
    end
    if @template then
      $merbout = ''
      self.tokenize
      self.source
    end

    if out_file then
      File.unlink(out_file) if File.exist? out_file
      File.open(out_file, 'w') do |f|
        f.write $merbout
      end
    end
    return $merbout
  end

  def tokenize
    @tokens = []
    raise RuntimeError, "Open and close tags must have the same length!" unless @tags[:open].length == @tags[:close].length
    return unless @template.is_a? String
    state  = [:text]
    chunk  = ''
    tag_l  = @tags[:open].length
    window = ' ' * tag_l
    # inizio scansione
    # filtro fine linea
    @template.gsub!( /\r\n/m, "\n" ) ;
    @template.gsub!( /\r/m, "\n" ) ;
    @template.each_char do |c|
      window = window[1..-1] + c # tiene finestra ultimi caratteri letti
      case state[-1]
      when :text then
        if window == @tags[:open] then
          # cerco di classificare il pezzo di testo
          tmp = chunk[0..-tag_l] ;
          if tmp.length > 0 then # se 2 tag consecutivi! niente testo
            if tmp =~ /^( |\t)*$/ then
              @tokens << [tmp, :blank]
            else
              @tokens << [tmp, :text]
            end
          end
          chunk = ''
          state << :ruby
        elsif c == "\n"
          if chunk =~ /^( |\t)*$/ then
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
          if chunk[0] == '=' then
            if chunk[-1] == '-' then
              @tokens << [chunk[1..-tag_l-1], :ruby_minus]
            else
              @tokens << [chunk[1..-tag_l], :ruby]
            end
          else
            @tokens << [chunk[0..-tag_l], :ruby_cmd]
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
  
  def source
    @commands = "$merbout = '';\n"
    last_tag  = [:null,:null,:null,:null]
    @commands = []
    @tokens.each { |chunk, type|
      case type
      when :ruby_minus then
        @commands << "$merbout.concat((#{chunk}).to_s);\n"
      when :ruby then
        @commands << "$merbout.concat((#{chunk}).to_s);\n"
      when :ruby_cmd then
        @commands << chunk + ";\n"
      when :text, :text_nl
        chunk.gsub!( /\\/m, "\\\\" ) ;
        chunk.gsub!( /\"/m, "\\\"" ) ;
        chunk.gsub!( /\'/m, "\\\'" ) ;
        chunk.gsub!( /\`/m, "\\\`" ) ;
        chunk.gsub!( /\#/m, "\\\#" ) ; # filtra comandi #{}
        if type == :text then
          @commands << "$merbout.concat \"#{chunk}\";\n" 
        else
          @commands << "$merbout.concat \"#{chunk}\\n\"; # :text_nl \n" 
        end
      when :blank_nl then
        @commands << "$merbout.concat \"#{chunk}\\n\"; # :blank_nl\n" if last_tag != :ruby_cmd
      when :blank then
        @commands << "$merbout.concat \"#{chunk}\"; # :blank\n"
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
        @commands.pop
      elsif last_tag[1..-1] == [:blank_nl,:ruby_cmd,:blank_nl] then
        last_tag = [:null,:null,:null,:blank_nl]
        @commands.pop
      end
    }
    eval @commands.join
  end
end

# 000000000000000000

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
