#
# racc scanner tester
#

require 'racc/raccs'

class ScanError < StandardError; end

def testdata(dir, argv)
  if argv.empty?
    Dir.glob(dir + '/*') -
      Dir.glob(dir + '/*.swp') -
      [dir + '/CVS']
  else
    argv.collect { |i| dir + '/' + i }
  end
end

if ARGV.delete '--print'
  $raccs_print_type = true
  printonly = true
else
  printonly = false
end

testdata(File.dirname($PROGRAM_NAME) + '/scandata', ARGV).each do |file|
  $stderr.print File.basename(file) + ': '
  begin
    ok = File.read(file)
    s = Racc::GrammarFileScanner.new(ok)
    sym, (val, _lineno) = s.scan
    if printonly
      warn
      warn val
      next
    end

    val = '{' + val + "}\n"
    sym == :ACTION or raise ScanError, 'is not action!'
    val == ok or raise ScanError, "\n>>>\n#{ok}----\n#{val}<<<"

    warn 'ok'
  rescue StandardError => err
    warn 'fail (' + err.type.to_s + ')'
    warn err.message
    warn err.backtrace
    warn
  end
end
