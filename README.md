```
..............................................
..####...#####....####...##....##..##...####..
.##......##..##..##......##.....####...##..##.
..####...#####....####...##......##.......##..
.....##..##..##......##..##......##......##...
..####...##..##...####...######..##......##...
..............................................
```

```ruby
require 'srsly'

r = SRSLY?                                  # Default "Are you sure (Y/N)?" message
r = SRSLY? nil => :eof                      # Returns :eof on EOF (nil)

r = SRSLY? 'Continue (Y/N)? '               # Custom message
r = SRSLY? 'Continue (Y/N)? ', nil => :eof  # Returns :eof on EOF

r = SRSLY? 'Seriously (Y/N/A)? ',
         # Expected responses (Regexp or String)
           /^y/i  => true,
           /^n/i  => false,
           /^a/i  => :all,
         # Other options
           :error => 'Invalid input. Seriously (Y/N/A)? ',
           :tries => 5,
           :in    => $stdin,
           :out   => $stdout

r = SRSLY? "A or B? ",
           'A'    => :a,
           'B'    => :b,
           nil    => :quit,
           :tries => 5,
           :error => proc { |got, try, total| print "#{got}? Try again (#{try}/#{total}) " },
           :out   => proc { |msg| print msg + '>> ' }
```
