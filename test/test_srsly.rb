$VERBOSE = true

require 'rubygems'
require 'minitest/autorun'
require 'mocha/setup'
require 'srsly'

class TestSRSLY < MiniTest::Test
  def setup
    $stdin = STDIN
    $stdout = STDOUT
  end

  def test_srsly_invalid_opts
    assert_raises(ArgumentError) { SRSLY? nil }
    assert_raises(ArgumentError) { SRSLY? "message0", "m", :tries => 1 }
    assert_raises(ArgumentError) { SRSLY? "message1", :tries => -1 }
    assert_raises(ArgumentError) { SRSLY? "message2", :tries => 0.1 }
    assert_raises(ArgumentError) { SRSLY? "message3", :in => "In" }
    assert_raises(ArgumentError) { SRSLY? "message4", :out => "Out" }
    assert_raises(ArgumentError) { SRSLY? "message5", :error => 1 }
  end

  def test_srsly_basic
    m = "SRSLY? (Y/N) "

    {
      :io_procs   => [:call, :call],
      :io_streams => [:gets, :write]
    }.each do |io, ms|
      {
        %w[y Y yes Yes] => true,
        %w[n N no No]   => false,
      }.each do |resps, exp|
        resps.each do |resp|
          i, o = self.send io
          o.expects(ms[1]).times(3).with(m).returns(m)
          o.expects(ms[1]).times(1).with($/).returns($/)
          o.expects(ms[1]).times(1).with(m).returns(m)
          i.expects(ms[0]).times(4).returns('???', '???', nil, resp + $/)

          assert_equal exp, SRSLY?(m, :in => i, :out => o)
        end
      end
    end
  end

  def test_srsly_multiple_patterns
    m = "(a/b/c) "
    m2 = "Hey!!"

    {
      :io_procs   => [:call, :call],
      :io_streams => [:gets, :write]
    }.each do |io, ms|
      {
        %w[a A]    => :a,
        %w[b B ab] => :b,
        %w[c C]    => :c,
      }.each do |resps, exp|
        resps.each do |resp|
          i, o = self.send io
          o.expects(ms[1]).times(1).with(m).returns(m)
          o.expects(ms[1]).times(2).with(m2).returns(m2)
          o.expects(ms[1]).times(1).with($/).returns($/)
          o.expects(ms[1]).times(1).with(m2).returns(m2)
          i.expects(ms[0]).times(4).returns('???', '???', nil, resp + $/)

          assert_equal exp, SRSLY?(m, :error => m2,
                                     'a'  => :a, 'A' => :a,
                                     /b/i => :b,
                                     /c/  => :c, 'C' => :c,
                                     :in  => i, :out => o)
        end
      end
    end
  end

  def test_srsly_fail
    m = "(a/b/c) "
    m2 = "Hey!!"
    f = 'Duh'

    {
      :io_procs   => [:call, :call],
      :io_streams => [:gets, :write]
    }.each do |io, ms|
      i, o = self.send io
      o.expects(ms[1]).times(1).with(m).returns(m)
      o.expects(ms[1]).times(2).with(m2).returns(m2)
      o.expects(ms[1]).times(1).with($/).returns($/)
      o.expects(ms[1]).times(1).with(m2).returns(m2)

      i.expects(ms[0]).times(4).returns('???', '???', nil, '???')

      assert_equal nil, SRSLY?(m,
                               :error => m2,
                               'a'  => :a, 'A' => :a,
                               /b/i => :b,
                               /c/  => :c, 'C' => :c,
                               :tries => 4,
                               :in  => i, :out => o)
    end
  end

  def test_srsly_nil
    i, o = io_procs

    m = "nil?"
    o.expects(:call).times(1).with(m).returns(m)
    o.expects(:call).times(1).with($/).returns($/)
    i.expects(:call).times(1).returns(nil)
    assert_equal :nil, SRSLY?(m, nil => :nil, :in  => i, :out => o)
  end

  def test_srsly_error_proc
    i, o = io_procs

    m = "Go!"
    o.expects(:call).times(1).with(m).returns(m)
    i.expects(:call).times(4).returns("???", "???", "???", "ok")

    cnt = 0
    assert_equal :ok,
      SRSLY?(m, :error => proc { |err, t, tot|
        cnt += 1
        assert_equal '???', err
        assert_equal cnt + 1, t
        assert_equal 5, tot
      }, :tries => 5, 'ok' => :ok, :in  => i, :out => o)

    assert_equal 3, cnt
  end

private
  def io_procs
    Array.new(2) {
      mock.tap { |m| m.expects(:is_a?).with(Proc).returns(true).once }
    }
  end

  def io_streams
    [
      mock.tap { |m| m.expects(:respond_to?).with(:gets).returns(true).once },
      mock.tap { |m| m.expects(:respond_to?).with(:write).returns(true).once }
    ]
  end
end
