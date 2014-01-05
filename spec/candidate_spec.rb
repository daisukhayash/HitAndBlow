# -*- encoding: utf-8 -*-

require (File.dirname(__FILE__) + '/spec_helper')
require 'hitandblow/solver'

describe HitAndBlow::Solver::Candidate do
  describe 'default' do
    it 'create an instance that has default digits' do
      number_of_digit = 4
      default_weight = 100.0
      add_point = 10.0
      HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
        .should eq [HitAndBlow::Solver::Candidate::Digit.default(default_weight),
                    HitAndBlow::Solver::Candidate::Digit.default(default_weight),
                    HitAndBlow::Solver::Candidate::Digit.default(default_weight),
                    HitAndBlow::Solver::Candidate::Digit.default(default_weight)]
    end
  end  

  describe 'setup' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    nums_1st = [0 ,1, 2]
    nums_2nd = [3, 4, 5]
    nums_3rd = [6, 7]
    nums_4th = [8, 9]
    nums_array = [nums_1st, nums_2nd, nums_3rd, nums_4th]
    digit_1st = HitAndBlow::Solver::Candidate::Digit.setup nums_1st
    digit_2nd = HitAndBlow::Solver::Candidate::Digit.setup nums_2nd
    digit_3rd = HitAndBlow::Solver::Candidate::Digit.setup nums_3rd
    digit_4th = HitAndBlow::Solver::Candidate::Digit.setup nums_4th
    it 'create an instance that has given values' do
      HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
        .should eq [digit_1st, digit_2nd, digit_3rd, digit_4th]
    end
  end

  describe 'pick_at_random' do
    it 'should return 4-digit-String that picked at random' do
      number_of_digit = 4
      default_weight = 100.0
      add_point = 10.0
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      candidate.pick_at_random.should match /[0-9]{4}/
    end
  end

  describe 'number_of_number(start_position=0, exclude=[])' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    nums_array = [[0, 1, 3],
                  [3, 5],
                  [0, 7, 8],
                  [7, 9]]
    candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
    it 'return number of numbers left' do
      candidate.number_of_number.should eq 7
    end
    it 'return number of numbers after the start position' do
      candidate.number_of_number(1).should eq 6
      candidate.number_of_number(2).should eq 4
      candidate.number_of_number(3).should eq 2
    end
    it 'return number of numbers without given numbers' do
      candidate.number_of_number(0, [5, 7]).should eq 5
      candidate.number_of_number(1, [5, 8, 9]).should eq 3
      candidate.number_of_number(2, [0, 7, 8, 9]).should eq 0
      candidate.number_of_number(3, [9]).should eq 1
    end
  end

  describe 'take_in_answer(answer, hit, blow)' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    it 'add the answer to history' do
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      candidate.take_in_answer '1234', 1, 1
      candidate.history.should eq [['1234', 1, 1]]
      candidate.take_in_answer '5678', 2, 1
      candidate.history.should eq [['1234', 1, 1], ['5678', 2, 1]]
    end

    context 'when HIT = 0' do
      it 'remove each number from its own digit' do
        candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
        candidate.take_in_answer '0123', 0, 1
        candidate[0].numbers.should eq [1, 2, 3, 4, 5, 6, 7, 8, 9]
        candidate[1].numbers.should eq [0, 2, 3, 4, 5, 6, 7, 8, 9]
        candidate[2].numbers.should eq [0, 1, 3, 4, 5, 6, 7, 8, 9]
        candidate[3].numbers.should eq [0, 1, 2, 4, 5, 6, 7, 8, 9]
        
        candidate.take_in_answer '6789', 0, 1
        candidate[0].numbers.should eq [1, 2, 3, 4, 5, 7, 8, 9]
        candidate[1].numbers.should eq [0, 2, 3, 4, 5, 6, 8, 9]
        candidate[2].numbers.should eq [0, 1, 3, 4, 5, 6, 7, 9]
        candidate[3].numbers.should eq [0, 1, 2, 4, 5, 6, 7, 8]
      end
    end

    context 'when BLOW = 0' do
      it 'remove each number from the other digits' do
        candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
        candidate.take_in_answer '0123', 1, 0
        candidate[0].numbers.should eq [0, 4, 5, 6, 7, 8, 9]
        candidate[1].numbers.should eq [1, 4, 5, 6, 7, 8, 9]
        candidate[2].numbers.should eq [2, 4, 5, 6, 7, 8, 9]
        candidate[3].numbers.should eq [3, 4, 5, 6, 7, 8, 9]
        
        candidate.take_in_answer '6789', 1, 0
        candidate[0].numbers.should eq [0, 4, 5, 6]
        candidate[1].numbers.should eq [1, 4, 5, 7]
        candidate[2].numbers.should eq [2, 4, 5, 8]
        candidate[3].numbers.should eq [3, 4, 5, 9]
      end
    end

    context 'when HIT + BLOW = 4' do
      it 'remove the other number from all digits' do
        candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
        candidate.take_in_answer '0123', 1, 3
        candidate[0].numbers.should eq [0, 1, 2, 3]
        candidate[1].numbers.should eq [0, 1, 2, 3]
        candidate[2].numbers.should eq [0, 1, 2, 3]
        candidate[3].numbers.should eq [0, 1, 2, 3]
      end
    end

    context 'when BLOW = 4' do
      it 'remove each number from the other digits' do
        candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
        candidate.take_in_answer '0123', 0, 4
        candidate[0].numbers.should eq [1, 2, 3]
        candidate[1].numbers.should eq [0, 2, 3]
        candidate[2].numbers.should eq [0, 1, 3]
        candidate[3].numbers.should eq [0, 1, 2]
      end
    end

    context 'when one of digit has just one number' do
      it 'remove the number from the other digit' do
        nums_array = [[0, 1, 2, 3],
                      [3],
                      [0, 3, 4, 5],
                      [0]]
        candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
        candidate.take_in_answer '0123', 1, 1
        candidate[0].numbers.should eq [1, 2]
        candidate[1].numbers.should eq [3]
        candidate[2].numbers.should eq [4, 5]
        candidate[3].numbers.should eq [0]
      end
    end

    context 'when two of digits have same two numbers' do
      it 'remove the numbers from the other digit' do
        nums_array = [[0, 1, 2, 3],
                      [1, 3],
                      [0, 3, 4, 5],
                      [1, 3]]
        candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
        candidate.take_in_answer '0123', 1, 1
        candidate[0].numbers.should eq [0, 2]
        candidate[1].numbers.should eq [1, 3]
        candidate[2].numbers.should eq [0, 4, 5]
        candidate[3].numbers.should eq [1, 3]
      end
    end

    context 'when three of digits have same tree numbers' do
      it 'remove the numbers from the other digit' do
        nums_array = [[1, 2, 3],
                      [1, 2, 3],
                      [0, 1, 2, 3, 4, 5],
                      [1, 2, 3]]
        candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
        candidate.take_in_answer '0123', 1, 1
        candidate[0].numbers.should eq [1, 2, 3]
        candidate[1].numbers.should eq [1, 2, 3]
        candidate[2].numbers.should eq [0, 4, 5]
        candidate[3].numbers.should eq [1, 2, 3]
      end
    end

    context 'when there are 4 numbers left and one of digit has the number that the other do not' do
      it 'remove the number from the other digit' do
        nums_array = [[1, 3],
                      [1, 3],
                      [0, 1],
                      [1, 2]]
        candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
        candidate.take_in_answer '0123', 1, 1
        candidate[0].numbers.should eq [1, 3]
        candidate[1].numbers.should eq [1, 3]
        candidate[2].numbers.should eq [0]
        candidate[3].numbers.should eq [2]
      end
    end
  end

  describe 'has_tried?(num)' do
    it 'should be true if the number has been tried' do
      number_of_digit = 4
      default_weight = 100.0
      add_point = 10.0
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      answer = '1234'
      candidate.take_in_answer answer, 1, 1
      candidate.has_tried?(answer).should be_true
      candidate.has_tried?('5678').should be_false
    end
  end

  describe 'all_digits_have_trash' do
    it 'should be true if all digits have trash' do
      number_of_digit = 4
      default_weight = 100.0
      add_point = 10.0
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      candidate.all_digits_have_trash?.should be_false
    end
  end

  describe 'true_trashes' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    it 'return array of trashes that is trash on all digits' do
      nums_array = [[0, 2],
                    [2, 3, 4],
                    [5, 6],
                    [7, 8]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq [1, 9]
    end

    it 'return array of trashes that is trash on all digits' do
      nums_array = [[1, 2, 3],
                    [2, 3, 7],
                    [1, 3, 7],
                    [2, 3, 7]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq [0, 4, 5, 6, 8, 9]
    end

    it 'return empty array if there was no all-digits-trash' do
      nums_array = [[0, 1, 2],
                    [3, 4],
                    [5, 6],
                    [7, 8, 9]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq []
    end
  end

  describe 'true_trashes(*exept)' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    it 'return array of trashes that is trash on all digits except given' do
      nums_array = [[0, 2],
                    [2, 3, 4],
                    [5, 6],
                    [7, 8]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes(2).should eq [1, 5, 6, 9]
    end
  end

  describe 'reviewed_history' do
    it 'return Array of history' do
      number_of_digit = 4
      default_weight = 100.0
      add_point = 10.0
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      candidate.take_in_answer '2345', 1, 1
      candidate.take_in_answer '0456', 0, 0
      candidate.take_in_answer '0189', 1, 0
      candidate.take_in_answer '1678', 0, 0
      candidate.reviewed_history.should eq [[[2, 3, nil, nil], 1, 1],
                                            [[nil, nil, nil, 9], 1, 0]]
    end
  end

  describe 'try_between_two' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    it 'return answer if there was digit that has two numbers' do
      nums_array = [[0, 2],
                    [2, 3, 4],
                    [5, 6],
                    [6, 7]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq [1, 8, 9]
      candidate.try_between_two.should eq '0189'
    end

    it 'return answer if there was digit that has two numbers' do
      nums_array = [[0, 1, 2],
                    [3, 4],
                    [0, 3],
                    [7, 8]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq [5, 6, 9]
      candidate.try_between_two.should eq '5369'
    end

    it 'return answer if there was digit that has two numbers' do
      nums_array = [[0, 2, 4],
                    [0, 4, 5],
                    [2, 4, 5],
                    [7, 8]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq [1, 3, 6, 9]
      candidate.try_between_two.should eq '1367'
    end

    it 'return nil if there was not digit that has two numbers' do
      nums_array = [[0, 1, 2],
                    [3, 4, 5],
                    [5, 6, 7],
                    [7, 8, 9]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.try_between_two.should be_nil
    end

    it 'return nil if there was no enough trash' do
      nums_array = [[0, 1],
                    [3, 4, 5],
                    [5, 6, 7],
                    [7, 8, 9]]
      candidate = HitAndBlow::Solver::Candidate.setup(number_of_digit, add_point, nums_array)
      candidate.true_trashes.should eq [2]
      candidate.try_between_two.should be_nil
    end
  end

  describe 'try_hit_history' do
    number_of_digit = 4
    default_weight = 100.0
    add_point = 10.0
    it 'return answer that was derived from the history' do
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      candidate.take_in_answer '2345', 1, 0
      candidate.take_in_answer '0456', 0, 0
      candidate.reviewed_history.should eq [[[2, 3, nil, nil], 1, 0]]
      candidate.try_hit_history.should eq '2045'
    end

    it 'return answer that was derived from the history' do
      candidate = HitAndBlow::Solver::Candidate.default(number_of_digit, default_weight, add_point)
      candidate.take_in_answer '2345', 1, 0
      candidate.take_in_answer '0123', 0, 0
      candidate.reviewed_history.should eq [[[nil, nil, 4, 5], 1, 0]]
      candidate.try_hit_history.should eq '0142'
    end
  end
  describe 'take_in_history' do
  end
end
