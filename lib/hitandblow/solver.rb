# -*- encoding: utf-8 -*-

module HitAndBlow
  class Solver
    class Candidate < Array
      class Digit < Array
        def initialize
          @trashbox = []
        end
        attr_accessor :trashbox

        def self.default default_weight
          obj = self.new
          (0..9).each do |number|
            obj << [number, default_weight]
          end
          return obj
        end

        def self.setup numbers
          default_weight = 100.0
          obj = self.new
          numbers.each do |num, weight|
            obj << [num, weight||default_weight]
          end
          ((0..9).to_a - obj.numbers).each do |num|
            obj.trashbox << num
          end
          return obj
        end

        def self.empty; self.new; end

        def number_at(idx); (it = self[idx]).nil? ? nil : it[0]; end

        def weight_at(idx); (it = self[idx]).nil? ? nil : it[1]; end

        def weight_of(num); (it = assoc(num)).nil? ? nil : it[1]; end
        
        def numbers; map { |number, weight| number }; end

        def include?(num); any? { |v| v[0] == num }; end

        def has_trash?; not @trashbox.empty?; end

        def trashes; @trashbox; end

        def pick_up_trash *except
          return nil unless has_trash?
          (@trashbox - except).first
        end

        def add_weight(num, w); assoc(num)[1] += w unless assoc(num).nil?; end

        def remove *num
          num.each do |n|
            i = index { |v| v[0] == n }
            next if i.nil?
            trash = slice!(i)
            @trashbox << trash.first
          end
          self
        end
        
        def exclude ex_array
          map { |v| v unless ex_array.include? v[0] }.compact
        end

        def pick_at_random _exclude=[]
          r = rand
          ary = exclude(_exclude)
          total = ary.inject(0) { |sum, ary| sum + ary[1] }
          ary
            .sort { |a, b| b[1] <=> a[1] } # descending order of weight
            .map { |ary| [ary[0], ary[1] / total] }
            .inject(0) { |sum, ary| sum += ary[1]; return ary[0] if r < sum; sum }
        end
      end

      def initialize number_of_digit, point
        @number_of_digit = number_of_digit
        @point = point
        @history = []
      end
      attr_accessor :history

      def self.default(number_of_digit, default_weight, point)
        obj = self.new(number_of_digit, point)
        (0...number_of_digit).to_a.each do |idx|
          obj << Digit.default(default_weight)
        end
        return obj
      end

      def self.setup number_of_digit, point, numbers
        obj = self.new(number_of_digit, point)
        numbers.each do |nums|
          obj << Digit.setup(nums)
        end
        return obj
      end

      alias each_digit each
      alias each_digit_with_index each_with_index

      def each_digit_except *exception_idx
        indexes = ((0...@number_of_digit).to_a - exception_idx)
        if block_given?
          indexes.each do |i|
            yield self[i]
          end
        else
          indexes.map { |i| self[i] }
        end
      end

      def has_tried? num
        @history.any? { |hist, hit, blow| hist == num }
      end

      def all_digits_have_trash?
        self.all? { |digit| digit.has_trash? }
      end

      def true_trashes *except
        each_digit_except(*except).map { |digit| digit.trashes }.inject { |a, b| a & b }.sort
      end

      class InfiniteLoopError < RuntimeError; end
      def pick_at_random
        ex = []
        begin
          each_digit_with_index.inject("") do |ret, (digit, idx)|
            sub_ex = []
            temp_num = nil
            loop_counter = 0
            loop do
              temp_num = digit.pick_at_random(ex + sub_ex)
              break if idx >= 3

              loop_counter += 1
              raise InfiniteLoopError if loop_counter > 10

              sub_ex << temp_num
              next if (idx + 1...@number_of_digit).any? { |idx| (self[idx].numbers - ex - [temp_num]).size == 0 }
              next if number_of_number(idx + 1, ex + [temp_num]) < (4 - idx - 1)
              break
            end
            ex << temp_num unless ex.include? temp_num
            ret += temp_num.to_s
            ret
          end
        rescue InfiniteLoopError => e
          retry
        end
      end

      def reviewed_history
        ret =[]
        @history.each do |answer, hit, blow|
          next if hit == 0 and blow == 0

          answer = answer.split(//).map { |s| s.to_i }
          reviewed = []
          answer.each_with_index do |num, idx|
            reviewed << (self[idx].include?(num) ? num : nil)
          end
          ret << [reviewed, hit, blow]
        end
        ret
      end

      def try_between_two
        flg = true
        val_idx = nil
        ret = each_digit_with_index.map do |digit, idx|
          if digit.size == 2 and flg
            flg = false
            val_idx = idx
            digit.number_at(0)
          else
            nil
          end
        end
        return nil if ret.all? { |n| n.nil? }

        trashes = true_trashes - ret
        each_digit_with_index do |digit, idx|
          if ret[idx].nil?
            ret[idx] = trashes.shift
          end
        end
        return ret.all? { |n| not n.nil? } ? ret.join : nil
      end

      def try_hit_history
        reviewed_history.each do |answer, hit, blow|
          living_count = answer.inject(0) { |sum, v| sum += (v.nil? ? 0 : 1) }
          if blow == 0 and living_count == hit + 1
            flg = true
            val_idx = nil
            ret = answer.each_with_index.map do |n, idx|
              if not(n.nil?) and flg
                flg = false
                val_idx = idx
                n
              else
                nil
              end
            end

            trashes = true_trashes - ret
            each_digit_with_index do |digit, idx|
              if ret[idx].nil?
                ret[idx] = trashes.shift
              end
            end
            return ret.all? { |n| not n.nil? } ? ret.join : nil
          end
        end
        return nil
      end
  
      def take_in_history
        reviewed_history.each do |answer, hit, blow|
          n_1st = i_1st = n_2nd = i_2nd = nil
          living_count = 0
          answer.each_with_index do |num, idx|
            unless num.nil?
              living_count += 1
              if n_1st.nil?
                n_1st = num; i_1st = idx
              else
                n_2nd = num; i_2nd = idx
              end
            end
          end
          if living_count == hit and blow == 0
            answer.each_with_index do |hit_num, idx|
              self[idx].select! { |num, weight| num == hit_num } unless hit_num.nil?
            end
          end
          if living_count == blow and hit == 0 and blow == 2
            self[i_2nd].select! { |num, weight| num == n_1st }
            self[i_1st].select! { |num, weight| num == n_2nd }
          end
        end
      end

      def number_of_number start_position=0, exclude=[]
        ((start_position...@number_of_digit).map { |idx| self[idx].numbers }.flatten.uniq - exclude).size
      end

      def take_in_answer answer, hit, blow
        @history << [answer, hit, blow]
        answer = answer.split(//).map { |s| s.to_i }

        if (hit + blow) == 4
          each_digit do |digit|
            digit.remove *((0..9).to_a - answer)
          end
        end
        if hit == 0
          answer.each_with_index do |num, idx|
            self[idx].remove num
          end
        else
          answer.each_with_index do |num, idx|
            self[idx].add_weight num, @point
          end
        end
        if blow == 0
          answer.each_with_index do |num, idx|
            each_digit_except(idx) do |digit|
              digit.remove num
            end
          end
        else
          answer.each_with_index do |num, idx|
            each_digit_except(idx) do |digit|
              digit.add_weight num, @point
            end
          end
        end

        each_digit_with_index do |digit, idx|
          if digit.size == 1
            each_digit_except(idx) do |dig|
              dig.remove *digit.numbers
            end
          else
            same = each_digit_except(idx).inject(0) { |sum, dig| sum += 1 if digit == dig; sum }
            if same == digit.size - 1
              each_digit_except(idx) do |dig|
                dig.remove *digit.numbers unless digit == dig
              end
            end
          end
        end

        if number_of_number == 4
          each_digit_with_index do|digit, idx|
            only = Digit.empty
            digit.each do |d|
              only << d if each_digit_except(idx).all? { |digit| not digit.include?(d[0]) }
            end
            self[idx] = only unless only.empty?
          end
        end

        take_in_history
      end
    end
    
    def initialize default_weight, point
      @candidate = Candidate.default(4, default_weight, point)
    end

    def expect
      [:try_between_two, :try_hit_history].each do |method|
        cand = @candidate.send(method)
        next if cand.nil? or @candidate.has_tried?(cand)
        return cand
      end

      loop do
        cand = @candidate.pick_at_random
        next if cand.nil? or @candidate.has_tried?(cand)
        return cand
      end
    end

    def feedback answer, hit, blow
      @candidate.take_in_answer answer, hit.to_i, blow.to_i
    end
  end
end
