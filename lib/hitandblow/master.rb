# -*- encoding: utf-8 -*-

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'solver'

class Array
  def sum
    inject(0.0) { |result, el| result + el }
  end

  def mean 
    sum / size
  end

  def median
    sorted = sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end
end

results = []
(1..100).to_a.map { |n| n.to_f }.each do |n|
  res = []
  30.times do
    count = 0

    right_answer = (0..9).to_a.sample(4).join
    puts "right_answer #{right_answer}"

    hb = HitAndBlow::Solver.new(100.0, n)

    loop do
      answer = hb.expect
      if answer.nil? or answer.split(//).compact.uniq.size < 4
        raise RuntimeError, answer
      end

      puts "try #{answer}"
      hit = blow = 0
      right_answer.split(//).each_with_index do |n, right_idx|
        [0,1,2,3].each do |answer_idx|
          if answer[answer_idx] == n
            if right_idx == answer_idx
              hit += 1
            else
              blow += 1
            end
          end
        end
      end

      count += 1
      hint = "#{count}:H#{hit}B#{blow}"
      puts hint
      if hit >= 4
        # puts "You get the right answer"
        res << count
        break
      end
      hb.feedback answer, hit, blow
    end

  end
  results << "point:%5.1f min:%5.1f median:%5.1f mean:%5.1f max:%5.1f" % [n, res.min, res.median, res.mean, res.max]
end

results.each do |res|
  puts res
end
