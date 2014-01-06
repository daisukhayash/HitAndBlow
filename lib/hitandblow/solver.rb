# -*- encoding: utf-8 -*-

=begin rdoc
Hit & Blow を解く
=end

module HitAndBlow

  # Hit & Blow を解くクラス
  #
  # Sample
  # hab = Solver.default(100.0)
  # p hab.expect #=> '0123'
  # hab.feedback('0123', 2, 2)
  # p hab.expect #=> '3102'
  class Solver

    # 4 桁の数字を保持し、回答の出力や結果の取込を行うクラス
    class Candidate < Array

      # 1 桁の数字を保持するクラス。
      class Digit < Array

        # 新しいインスタンスを生成する。
        # 通常直接呼ばれることはなく、default や setup を使用する。
        def initialize
          @trashbox = []
        end

        # 候補から外れた数字の配列
        attr_accessor :trashbox

        # 0 から 9 を候補として保持するインスタンスを生成する。
        # それぞれの数字に持たせる重みの初期値を引数に指定する。
        # ==== Args
        # default_weight :: 重みの初期値を Float で指定。数字のランダム出力に使用する。
        # ==== Return
        # 生成されたインスタンス。
        def self.default default_weight
          obj = self.new
          (0..9).each do |number|
            obj << [number, default_weight]
          end
          return obj
        end

        # 渡された数字を候補として保持するインスタンスを生成する。
        # ==== Args
        # numbers :: 候補として持たせる数字の配列
        # ==== Return
        # 生成されたインスタンス。
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

        # 候補となる数字を持たない空のインスタンスを生成する。
        # ==== Return
        # 空のインスタンス。
        def self.empty; self.new; end

        # 指定された位置の数字を返す。
        # ==== Args
        # idx :: 配列のインデックス。
        # ==== Return
        # インデックス位置の数字。
        def number_at(idx); (it = self[idx]).nil? ? nil : it[0]; end

        # 指定された位置の数字の重みを返す。
        # ==== Args
        # idx :: 配列のインデックス。
        # ==== Return
        # インデックス位置の数字の重み。
        def weight_at(idx); (it = self[idx]).nil? ? nil : it[1]; end

        # 指定された数字の重みを返す。
        # ==== Args
        # num :: 重みを取得したい数字。
        # ==== Return
        # 指定された数字の重み。
        def weight_of(num); (it = assoc(num)).nil? ? nil : it[1]; end

        # 候補の数字の配列を返す。
        # ==== Return
        # 候補の数字の配列。
        def numbers; map { |number, weight| number }; end

        # 指定した数字が候補に含まれるかどうか。
        # ==== Args
        # num :: 数字。
        # ==== Return
        # true :: 数字が候補に含まれる。
        # false :: 数字が候補に含まれない。
        def include?(num); any? { |v| v[0] == num }; end

        # 候補から外れた数字が存在するか。
        # ==== Return
        # true :: 存在する。
        # false :: 存在しない。
        def has_trash?; not @trashbox.empty?; end

        # 候補から外れた数字を配列で返す。
        # ==== Return
        # 数字の配列。
        def trashes; @trashbox; end

        # 候補から外れている数字を一つ返す。
        # ==== Args
        # *except :: 除外したい数字を指定する。（複数指定可。省略可。）
        # ==== Return
        # 候補から外れた数字
        def pick_up_trash *except
          return nil unless has_trash?
          (@trashbox - except).first
        end

        # 指定した数字に重みを加算する。
        # ==== Args
        # num :: 重みを加えたい数字。
        # weight :: 加算する値。
        def add_weight(num, w); assoc(num)[1] += w unless assoc(num).nil?; end

        # 指定した数字を候補から削除する。
        # ==== Args
        # num :: 削除する数字。
        def remove *num
          num.each do |n|
            i = index { |v| v[0] == n }
            next if i.nil?
            trash = slice!(i)
            @trashbox << trash.first
          end
          self
        end

        # 配列で指定された数字以外の候補を返す。
        # ==== Args
        # ex_array :: 除外する数字の配列。
        # ==== Return
        # 数字と重みの配列。
        def exclude ex_array
          map { |v| v unless ex_array.include? v[0] }.compact
        end

        # 候補から数字を一つランダムに選んで返す。
        # ランダム選択は重みを考慮して行う。
        # 数字の配列を引数に渡した場合、それらを除外して選択される。
        # ==== Args
        # exclude :: 除外したい数字の配列。
        # ==== Return
        # ランダム選択された数字。
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

      # 新しいインスタンスを生成する。
      # 通常直接呼ばれることはなく、default や setup を使用する。
      def initialize number_of_digit, point
        @number_of_digit = number_of_digit
        @point = point
        @history = []
      end

      # 回答と結果の履歴
      # [[回答, Hit数, Blow数]] ex)[['0123', 1, 2], ['4567', 0, 0]]
      attr_accessor :history

      # 0 から 9 を候補として保持するインスタンスを生成する。
      # ==== Args
      # number_of_digit :: 桁数を指定する。指定した数の分だけ内部で Digit インスタンスを保持する。
      # default_weight :: 重みの初期値を Float で指定。数字のランダム出力に使用する。
      # point :: 重みに加算する際の値を指定する。
      # ==== Return
      # 生成されたインスタンス。
      def self.default number_of_digit, default_weight, point
        obj = self.new(number_of_digit, point)
        (0...number_of_digit).to_a.each do |idx|
          obj << Digit.default(default_weight)
        end
        return obj
      end

      # 渡された数字を候補として保持するインスタンスを生成する。
      # ==== Args
      # number_of_digit :: 桁数を指定する。指定した数の分だけ内部で Digit インスタンスを保持する。
      # point :: 重みに加算する際の値を指定する。
      # numbers :: 候補として持たせる数字の配列の配列
      # ==== Return
      # 生成されたインスタンス。
      def self.setup number_of_digit, point, numbers
        obj = self.new(number_of_digit, point)
        numbers.each do |nums|
          obj << Digit.setup(nums)
        end
        return obj
      end

      alias each_digit each
      alias each_digit_with_index each_with_index

      # 指定された位置の桁以外の各桁に対してブロックを評価する。
      # ブロックが与えられなかった場合は、Enumelator オブジェクトを返す。
      # ==== Args
      # *exception_idx :: 除外したい桁の位置。複数指定可。
      # ==== Return
      # ブロックが与えられなかった場合、指定桁以外の各桁の Enumelator インスタンス。
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

      # 回答が既に試行されたことのあるものかどうか。
      # ==== Args
      # num :: 回答案。
      # ==== Return
      # true :: 試行済み。
      # false :: 試行済みでない。
      def has_tried? num
        @history.any? { |hist, hit, blow| hist == num }
      end

      # 全ての桁に候補から外れた数字が存在するかどうか。
      # ==== Return
      # true :: 存在する。
      # false :: 存在しない。
      def all_digits_have_trash?
        self.all? { |digit| digit.has_trash? }
      end

      # 全ての桁において候補から外れている数字の配列を返す。
      # 該当する数字が存在しない場合、空の配列が返る。
      # 引数に数字が与えられた場合、その数字を除外する。
      # ==== Args
      # *except :: 除外したい数字。複数指定可。省略可。
      # ==== Return
      # 数字の配列。
      def true_trashes *except
        each_digit_except(*except).map { |digit| digit.trashes }.inject { |a, b| a & b }.sort
      end

      class InfiniteLoopError < RuntimeError; end

      # 候補から回答案をランダムに作成して返す。
      # ==== Return
      # ランダムに作成された回答案。
      def pick_at_random
        ex = [] # 回答案に含めることに確定した数字
        begin
          each_digit_with_index.inject("") do |ret, (digit, idx)|
            sub_ex = [] # 仮に回答案に含めることにした数字
            temp_num = nil
            loop_counter = 0
            loop do
              # 当該桁の数字を仮定する。
              temp_num = digit.pick_at_random(ex + sub_ex)
              # 4桁目の場合は確定
              break if idx >= 3
              # ループ回数が一定を超えた場合は無限ループの恐れがあるため
              # 1桁目からやり直す。
              loop_counter += 1
              raise InfiniteLoopError if loop_counter > 10

              sub_ex << temp_num
              # 当該桁を仮定の数字にしたとして、後続桁が手詰まりになる（候補が無くなる）場合は、当該桁をやり直し
              next if (idx + 1...@number_of_digit).any? { |idx| (self[idx].numbers - ex - [temp_num]).size == 0 }
              # 当該桁を仮定の数字にしたとして、後続桁の候補数が残り桁数に満たない場合は、当該桁をやり直し
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

      # 現時点の候補を元に再度見直した回答履歴を返す。
      # 履歴の回答の各桁のうち、現時点の候補に存在しない桁を nil で置き換える。
      # ==== Return
      # [[回答の各桁の配列, Hit数, Blow数]] ex)[[[0, 1, 2, nil], 1, 2], [[nil, 5, nil, 7], 1, 0]]
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

      # 残る候補が 2 つになっている桁がある場合、いずれかに確定するための回答案を作成して返す。
      # 候補が 2 つの桁のうちの一つについては、いずれかの候補の数字を用い、その他の桁には候補から外れている数字を用いる。
      # 候補が 2 つの桁が存在しない場合、nil を返す。
      # ==== Return
      # 回答案。
      def try_between_two
        flg = true
        val_idx = nil
        # 候補が 2 つになっている桁を探し、それ以外を nil で埋めた配列を作成
        # ex) [nil, nil, 3, nil]
        ret = each_digit_with_index.map do |digit, idx|
          if digit.size == 2 and flg
            flg = false
            val_idx = idx
            digit.number_at(0)
          else
            nil
          end
        end
        # 候補が 2 つになっている桁が存在しない場合は nil を返して終了。
        return nil if ret.all? { |n| n.nil? }

        # 全ての桁において候補から外れている数字を使って配列内の nil を置き換える。
        trashes = true_trashes - ret
        each_digit_with_index do |digit, idx|
          if ret[idx].nil?
            ret[idx] = trashes.shift
          end
        end
        # 配列に nil が残っている（＝候補から外れている数字が不足している）場合は nil を返す。
        # そうでない場合は作成された回答案を返す。
        return ret.all? { |n| not n.nil? } ? ret.join : nil
      end

      # 回答履歴から桁を確定可能な回答案が作成できる場合、作成して返す。
      # 例えば、4桁の数字で H3B0 の場合、一つの数字を残して他の桁を候補から外れた数字で埋めた回答案を出せばいくつかの桁が必ず確定できる。
      # 具体的に、1234 で H3B0 の場合に 1xxx を出す（x は候補から外れている数字）。
      # 結果が H1B0 の場合、1桁目が 1 であることが確定できる。
      # 結果が H0B0 の場合、1桁目は 1 でないこと、および、2 〜 4 桁目が 234 であることが確定となる。
      # 回答案が作成できない場合、nil を返す。
      # ==== Return
      # 回答案。
      def try_hit_history
        reviewed_history.each do |answer, hit, blow|
          # 候補に残っている桁の数を求める。
          living_count = answer.inject(0) { |sum, v| sum += (v.nil? ? 0 : 1) }
          # 候補に残っている桁の数が Hit の数より一つ多い場合は続ける。
          if blow == 0 and living_count == hit + 1
            flg = true
            val_idx = nil
            # 候補に残っている桁を探し、それ以外を nil で埋めた配列を作成
            # ex) [nil, nil, 3, nil]
            ret = answer.each_with_index.map do |n, idx|
              if not(n.nil?) and flg
                flg = false
                val_idx = idx
                n
              else
                nil
              end
            end

            # 全ての桁において候補から外れている数字を使って配列内の nil を置き換える。
            trashes = true_trashes - ret
            each_digit_with_index do |digit, idx|
              if ret[idx].nil?
                ret[idx] = trashes.shift
              end
            end
            # 配列に nil が残っている（＝候補から外れている数字が不足している）場合は nil を返す。
            # そうでない場合は作成された回答案を返す。
            return ret.all? { |n| not n.nil? } ? ret.join : nil
          end
        end
        # 作成できなかった場合は nil を返す。
        return nil
      end

      # 履歴を再評価して得られる結果を候補に取り込む。
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

      # 候補に残っている数字の数を返す。
      # ==== Args
      # start_position :: 指定した場合、指定桁以降のみ対象とする。
      # exclude :: 指定した数字を除外する。
      # ==== Return
      # 候補に残っている数字の数。
      def number_of_number start_position=0, exclude=[]
        ((start_position...@number_of_digit).map { |idx| self[idx].numbers }.flatten.uniq - exclude).size
      end

      # 回答と結果を取り込む。
      # ==== Args
      # answer :: 回答
      # hit :: Hit 数
      # blow :: Blow 数
      def take_in_answer answer, hit, blow
        @history << [answer, hit, blow]
        answer = answer.split(//).map { |s| s.to_i }

        # Hit と Blow が足して桁数に等しいなら answer 以外の数字を全桁から削除
        if (hit + blow) == @number_of_digit
          each_digit do |digit|
            digit.remove *((0..9).to_a - answer)
          end
        end
        # Hit が 0 ならそれぞれの桁について自身の数字を削除
        if hit == 0
          answer.each_with_index do |num, idx|
            self[idx].remove num
          end
        else
          # Hit が 0 でないならそれぞれの桁について自身の数字に重みを加算
          answer.each_with_index do |num, idx|
            self[idx].add_weight num, @point
          end
        end
        # Blow が 0 なら自身以外の桁から自身の数字を削除
        if blow == 0
          answer.each_with_index do |num, idx|
            each_digit_except(idx) do |digit|
              digit.remove num
            end
          end
        else
          # Blow が 0 でないなら自身以外の桁について自身の数字に重みを加算
          answer.each_with_index do |num, idx|
            each_digit_except(idx) do |digit|
              digit.add_weight num, @point
            end
          end
        end

        # 候補が四つしか残っておらず、他の桁が候補に持たない数字を持っている桁があった場合、その桁はその数字に確定する。
        if number_of_number == 4
          each_digit_with_index do|digit, idx|
            only = Digit.empty
            digit.each do |d|
              only << d if each_digit_except(idx).all? { |digit| not digit.include?(d[0]) }
            end
            self[idx] = only unless only.empty?
          end
        end

        each_digit_with_index do |digit, idx|
          # 桁に候補が一つしか残っていないなら他の桁からその数字を削除
          if digit.size == 1
            each_digit_except(idx) do |dig|
              dig.remove *digit.numbers
            end
          else
            # 候補が自身と一致する桁が他に存在し、その数が候補の数と等しい場合、それら以外の桁からその数字を削除
            same = each_digit_except(idx).inject(0) { |sum, dig| sum += 1 if digit == dig; sum }
            if same == digit.size - 1
              each_digit_except(idx) do |dig|
                dig.remove *digit.numbers unless digit == dig
              end
            end
          end
        end

        take_in_history
      end
    end

    # 初期状態のインスタンスを生成する。
    # ==== Args
    # default_weight :: 重みの初期値を Float で指定。数字のランダム出力に使用する。
    # point :: 重みに加算する際の値を指定する。
    # ==== Return
    # 生成されたインスタンス。
    def initialize default_weight, point
      @candidate = Candidate.default(4, default_weight, point)
    end

    # 回答案を出力する。
    # ==== Return
    # 回答案。
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

    # 回答と結果を取り込む。
    # ==== Args
    # answer :: 回答
    # hit :: Hit 数
    # blow :: Blow 数
    def feedback answer, hit, blow
      @candidate.take_in_answer answer, hit.to_i, blow.to_i
    end
  end
end
