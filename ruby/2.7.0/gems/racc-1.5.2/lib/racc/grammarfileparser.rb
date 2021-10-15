#--
#
#
#
# Copyright (c) 1999-2006 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the same terms of ruby.
# see the file "COPYING".
#
#++

require 'racc'
require 'racc/compat'
require 'racc/grammar'
require 'racc/parserfilegenerator'
require 'racc/sourcetext'
require 'stringio'

module Racc
  grammar = Grammar.define do
    g = self

    g.class = seq(:CLASS, :cname, many(:param), :RULE, :rules, option(:END))

    g.cname = seq(:rubyconst) { |name|
      @result.params.classname = name
    }\
                  | seq(:rubyconst, '<', :rubyconst) do |c, _, s|
                      @result.params.classname = c
                      @result.params.superclass = s
                    end

    g.rubyconst = separated_by1(:colon2, :SYMBOL) { |syms|
      syms.map(&:to_s).join('::')
    }

    g.colon2 = seq(':', ':')

    g.param = seq(:CONV, many1(:convdef), :END) { |*|
      # @grammar.end_convert_block   # FIXME
    }\
                  | seq(:PRECHIGH, many1(:precdef), :PRECLOW) do |*|
                      @grammar.end_precedence_declaration true
                    end\
                  | seq(:PRECLOW, many1(:precdef), :PRECHIGH) do |*|
                      @grammar.end_precedence_declaration false
                    end\
                  | seq(:START, :symbol) do |_, sym|
                      @grammar.start_symbol = sym
                    end\
                  | seq(:TOKEN, :symbols) do |_, syms|
                      syms.each(&:should_terminal)
                    end\
                  | seq(:OPTION, :options) do |_, syms|
                      syms.each do |opt|
                        case opt
                        when 'result_var'
                          @result.params.result_var = true
                        when 'no_result_var'
                          @result.params.result_var = false
                        when 'omit_action_call'
                          @result.params.omit_action_call = true
                        when 'no_omit_action_call'
                          @result.params.omit_action_call = false
                        else
                          raise CompileError, "unknown option: #{opt}"
                        end
                      end
                    end\
                  | seq(:EXPECT, :DIGIT) do |_, num|
                      raise CompileError, "`expect' seen twice" if @grammar.n_expected_srconflicts
                      @grammar.n_expected_srconflicts = num
                    end

    g.convdef = seq(:symbol, :STRING) { |sym, code|
      sym.serialized = code
    }

    g.precdef = seq(:LEFT, :symbols) { |_, syms|
      @grammar.declare_precedence :Left, syms
    }\
                  | seq(:RIGHT, :symbols) do |_, syms|
                      @grammar.declare_precedence :Right, syms
                    end\
                  | seq(:NONASSOC, :symbols) do |_, syms|
                      @grammar.declare_precedence :Nonassoc, syms
                    end

    g.symbols = seq(:symbol) { |sym|
      [sym]
    }\
                  | seq(:symbols, :symbol) do |list, sym|
                      list.push sym
                      list
                    end\
                  | seq(:symbols, '|')

    g.symbol = seq(:SYMBOL) { |sym| @grammar.intern(sym) }\
                  | seq(:STRING) { |str| @grammar.intern(str) }

    g.options = many(:SYMBOL) { |syms| syms.map(&:to_s) }

    g.rules = option(:rules_core) { |list|
      add_rule_block list unless list.empty?
      nil
    }

    g.rules_core = seq(:symbol) { |sym|
      [sym]
    }\
                  | seq(:rules_core, :rule_item) do |list, i|
                      list.push i
                      list
                    end\
                  | seq(:rules_core, ';') do |list, *|
                      add_rule_block list unless list.empty?
                      list.clear
                      list
                    end\
                  | seq(:rules_core, ':') do |list, *|
                      next_target = list.pop
                      add_rule_block list unless list.empty?
                      [next_target]
                    end

    g.rule_item = seq(:symbol)\
                  | seq('|') do |*|
                      OrMark.new(@scanner.lineno)
                    end\
                  | seq('=', :symbol) do |_, sym|
                      Prec.new(sym, @scanner.lineno)
                    end\
                  | seq(:ACTION) do |src|
                      UserAction.source_text(src)
                    end
  end

  GrammarFileParser = grammar.parser_class

  raise 'Racc boot script fatal: S/R conflict in build' if grammar.states.srconflict_exist?
  raise 'Racc boot script fatal: R/R conflict in build' if grammar.states.rrconflict_exist?

  class GrammarFileParser # reopen
    class Result
      def initialize(grammar)
        @grammar = grammar
        @params = ParserFileGenerator::Params.new
      end

      attr_reader :grammar
      attr_reader :params
    end

    def self.parse_file(filename)
      parse(File.read(filename), filename, 1)
    end

    def self.parse(src, filename = '-', lineno = 1)
      new.parse(src, filename, lineno)
    end

    def initialize(debug_flags = DebugFlags.new)
      @yydebug = debug_flags.parse
    end

    def parse(src, filename = '-', lineno = 1)
      @filename = filename
      @lineno = lineno
      @scanner = GrammarFileScanner.new(src, @filename)
      @scanner.debug = @yydebug
      @grammar = Grammar.new
      @result = Result.new(@grammar)
      @embedded_action_seq = 0
      yyparse @scanner, :yylex
      parse_user_code
      @result.grammar.init
      @result
    end

    private

    def next_token
      @scanner.scan
    end

    def on_error(_tok, val, _values)
      v = if val.respond_to?(:id2name)
            val.id2name
          elsif val.is_a?(String)
            val
          else
            val.inspect
          end
      raise CompileError, "#{location}: unexpected token '#{v}'"
    end

    def location
      "#{@filename}:#{@lineno - 1 + @scanner.lineno}"
    end

    def add_rule_block(list)
      sprec = nil
      target = list.shift
      case target
      when OrMark, UserAction, Prec
        raise CompileError, "#{target.lineno}: unexpected symbol #{target.name}"
      end
      curr = []
      list.each do |i|
        case i
        when OrMark
          add_rule target, curr, sprec
          curr = []
          sprec = nil
        when Prec
          raise CompileError, "'=<prec>' used twice in one rule" if sprec
          sprec = i.symbol
        else
          curr.push i
        end
      end
      add_rule target, curr, sprec
    end

    def add_rule(target, list, sprec)
      act = if list.last.is_a?(UserAction)
              list.pop
            else
              UserAction.empty
            end
      list.map! { |s| s.is_a?(UserAction) ? embedded_action(s) : s }
      rule = Rule.new(target, list, act)
      rule.specified_prec = sprec
      @grammar.add rule
    end

    def embedded_action(act)
      sym = @grammar.intern("@#{@embedded_action_seq += 1}".intern, true)
      @grammar.add Rule.new(sym, [], act)
      sym
    end

    #
    # User Code Block
    #

    def parse_user_code
      line = @scanner.lineno
      _, *blocks = *@scanner.epilogue.split(/^----/)
      blocks.each do |block|
        header, *body = block.lines.to_a
        label0, pathes = *header.sub(/\A-+/, '').split('=', 2)
        label = canonical_label(label0)
        (pathes ? pathes.strip.split(' ') : []).each do |path|
          add_user_code label, SourceText.new(File.read(path), path, 1)
        end
        add_user_code label, SourceText.new(body.join(''), @filename, line + 1)
        line += (1 + body.size)
      end
    end

    USER_CODE_LABELS = {
      'header'  => :header,
      'prepare' => :header, # obsolete
      'inner'   => :inner,
      'footer'  => :footer,
      'driver'  => :footer # obsolete
    }.freeze

    def canonical_label(src)
      label = src.to_s.strip.downcase.slice(/\w+/)
      raise CompileError, "unknown user code type: #{label.inspect}" unless USER_CODE_LABELS.key?(label)
      label
    end

    def add_user_code(label, src)
      @result.params.public_send(USER_CODE_LABELS[label]).push src
    end
  end

  class GrammarFileScanner
    def initialize(str, filename = '-')
      @lines = str.b.split(/\n|\r\n|\r/)
      @filename = filename
      @lineno = -1
      @line_head = true
      @in_rule_blk = false
      @in_conv_blk = false
      @in_block = nil
      @epilogue = ''
      @debug = false
      next_line
    end

    attr_reader :epilogue

    def lineno
      @lineno + 1
    end

    attr_accessor :debug

    def yylex(&block)
      if @debug
        yylex0 do |sym, tok|
          $stderr.printf "%7d %-10s %s\n", lineno, sym.inspect, tok.inspect
          yield [sym, tok]
        end
      else
        yylex0(&block)
      end
    end

    private

    def yylex0
      begin
        until @line.empty?
          @line.sub!(/\A\s+/, '')
          if /\A\#/ =~ @line
            break
          elsif /\A\/\*/ =~ @line
            skip_comment
          elsif s = reads(/\A[a-zA-Z_]\w*/)
            yield [atom_symbol(s), s.intern]
          elsif s = reads(/\A\d+/)
            yield [:DIGIT, s.to_i]
          elsif ch = reads(/\A./)
            case ch
            when '"', "'"
              yield [:STRING, eval(scan_quoted(ch))]
            when '{'
              lineno = lineno()
              yield [:ACTION, SourceText.new(scan_action, @filename, lineno)]
            else
              @line_head = false if ch == '|'
              yield [ch, ch]
            end
          end
        end
      end while next_line
      yield nil
    end

    def next_line
      @lineno += 1
      @line = @lines[@lineno]
      if !@line or /\A----/ =~ @line
        @epilogue = @lines.join("\n")
        @lines.clear
        @line = nil
        if @in_block
          @lineno -= 1
          scan_error! format('unterminated %s', @in_block)
        end
        false
      else
        @line.sub!(/(?:\n|\r\n|\r)\z/, '')
        @line_head = true
        true
      end
    end

    ReservedWord = {
      'right'    => :RIGHT,
      'left'     => :LEFT,
      'nonassoc' => :NONASSOC,
      'preclow'  => :PRECLOW,
      'prechigh' => :PRECHIGH,
      'token'    => :TOKEN,
      'convert'  => :CONV,
      'options'  => :OPTION,
      'start'    => :START,
      'expect'   => :EXPECT,
      'class'    => :CLASS,
      'rule'     => :RULE,
      'end'      => :END
    }.freeze

    def atom_symbol(token)
      if token == 'end'
        symbol = :END
        @in_conv_blk = false
        @in_rule_blk = false
      else
        symbol = if @line_head and !@in_conv_blk and !@in_rule_blk
                   ReservedWord[token] || :SYMBOL
                 else
                   :SYMBOL
                 end
        case symbol
        when :RULE then @in_rule_blk = true
        when :CONV then @in_conv_blk = true
        end
      end
      @line_head = false
      symbol
    end

    def skip_comment
      @in_block = 'comment'
      until m = /\*\//.match(@line)
        next_line
      end
      @line = m.post_match
      @in_block = nil
    end

    $raccs_print_type = false

    def scan_action
      buf = ''
      nest = 1
      pre = nil
      @in_block = 'action'
      begin
        pre = nil
        if s = reads(/\A\s+/)
          # does not set 'pre'
          buf << s
        end
        until @line.empty?
          if s = reads(/\A[^'"`{}%#\/\$]+/)
            buf << (pre = s)
            next
          end
          case ch = read(1)
          when '{'
            nest += 1
            buf << (pre = ch)
          when '}'
            nest -= 1
            if nest == 0
              @in_block = nil
              buf.sub!(/[ \t\f]+\z/, '')
              return buf
            end
            buf << (pre = ch)
          when '#' # comment
            buf << ch << @line
            break
          when "'", '"', '`'
            buf << (pre = scan_quoted(ch))
          when '%'
            if literal_head? pre, @line
              # % string, regexp, array
              buf << ch
              case ch = read(1)
              when /[qQx]/n
                buf << ch << (pre = scan_quoted(read(1), '%string'))
              when /wW/n
                buf << ch << (pre = scan_quoted(read(1), '%array'))
              when /s/n
                buf << ch << (pre = scan_quoted(read(1), '%symbol'))
              when /r/n
                buf << ch << (pre = scan_quoted(read(1), '%regexp'))
              when /[a-zA-Z0-9= ]/n # does not include "_"
                scan_error! "unknown type of % literal '%#{ch}'"
              else
                buf << (pre = scan_quoted(ch, '%string'))
              end
            else
              # operator
              buf << '||op->' if $raccs_print_type
              buf << (pre = ch)
            end
          when '/'
            if literal_head? pre, @line
              # regexp
              buf << (pre = scan_quoted(ch, 'regexp'))
            else
              # operator
              buf << '||op->' if $raccs_print_type
              buf << (pre = ch)
            end
          when '$' # gvar
            buf << ch << (pre = read(1))
          else
            raise 'racc: fatal: must not happen'
          end
        end
        buf << "\n"
      end while next_line
      raise 'racc: fatal: scan finished before parser finished'
    end

    def literal_head?(pre, post)
      (!pre || /[a-zA-Z_0-9]/n !~ pre[-1, 1]) &&
        !post.empty? && /\A[\s\=]/n !~ post
    end

    def read(len)
      s = @line[0, len]
      @line = @line[len..-1]
      s
    end

    def reads(re)
      m = re.match(@line) or return nil
      @line = m.post_match
      m[0]
    end

    def scan_quoted(left, tag = 'string')
      buf = left.dup
      buf = "||#{tag}->" + buf if $raccs_print_type
      re = get_quoted_re(left)
      sv = @in_block
      @in_block = tag
      begin
        if s = reads(re)
          buf << s
          break
        else
          buf << @line
        end
      end while next_line
      @in_block = sv
      buf << "<-#{tag}||" if $raccs_print_type
      buf
    end

    LEFT_TO_RIGHT = {
      '(' => ')',
      '{' => '}',
      '[' => ']',
      '<' => '>'
    }.freeze

    CACHE = {}.freeze

    def get_quoted_re(left)
      term = Regexp.quote(LEFT_TO_RIGHT[left] || left)
      CACHE[left] ||= /\A[^#{term}\\]*(?:\\.[^\\#{term}]*)*#{term}/
    end

    def scan_error!(msg)
      raise CompileError, "#{lineno}: #{msg}"
    end
  end
end # module Racc
