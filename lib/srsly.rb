# Prompt user for an input.
# @param [String] message Output message
# @param [Hash] options Options
# @option options [String|Proc] :error Message to print, or Proc to call on unexpected input.
# @option options [Fixnum] :tries Number of tries.
# @option options [IO|Proc] :in
# @option options [IO|Proc] :out
# @return [Object]
def SRSLY? *args
  message, options =
    case args.length
    when 0
      [nil, {}]
    when 1
      case args.first
      when Hash
        [nil, args.first]
      when String
        [args.first, {}]
      else
        raise ArgumentError, "Invalid parameter"
      end
    when 2
      args
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
    end

  message ||= 'Are you sure (Y/N)? '
  options = {
    :error => nil,
    :tries => nil,
    :in    => $stdin,
    :out   => $stdout
  }.merge(options)

  error, tries, input, output = options.values_at(
    :error, :tries, :in, :out)

  raise ArgumentError, "Message must be a String" unless message.is_a?(String)
  raise ArgumentError, "Invalid :tries" unless tries.nil? ||
                                               (tries.is_a?(Fixnum) && tries > 0)

  read =
    if input.respond_to?(:gets)
      proc { input.gets }
    elsif input.is_a?(Proc)
      input
    else
      raise ArgumentError, "Invalid :in"
    end

  write =
    if output.respond_to?(:write)
      proc { |s| output.write s }
    elsif output.is_a?(Proc)
      output
    else
      raise ArgumentError, "Invalid :out"
    end

  alert =
    case error
    when String
      proc { write.call error }
    when Proc
      error
    else
      raise ArgumentError, "Invalid :error"
    end if error

  resps = options.select { |k, v| k.is_a?(Regexp) || k.is_a?(String) || k.nil? }
  resps = Hash[resps].merge(
    # Default responses if nothing given
    /^y/i => true,
    /^n/i => false) if resps.reject { |k, _| k.nil? }.empty?

  ask = proc { write.call message }
  t   = 0
  got = nil
  while tries.nil? || t < tries
    ask.call got, t += 1, tries

    if got = read.call
      got = got.chomp
    else
      write.call $/
    end

    resps.each do |k, v|
      case k
      when String, nil
        return v if k == got
      when Regexp
        return v if k.match got
      end
    end

    ask = alert if alert
  end

  nil
end
