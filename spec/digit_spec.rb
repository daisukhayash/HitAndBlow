# -*- encoding: utf-8 -*-

require (File.dirname(__FILE__) + '/spec_helper')
require 'hitandblow/solver'

describe HitAndBlow::Solver::Candidate::Digit do
  describe 'default' do
    it 'create an instance that has a set of 0-9 and default weight' do
      weight = 20.0
      HitAndBlow::Solver::Candidate::Digit.default(weight)
        .should eq [[0, weight],
                    [1, weight],
                    [2, weight],
                    [3, weight],
                    [4, weight],
                    [5, weight],
                    [6, weight],
                    [7, weight],
                    [8, weight],
                    [9, weight]]
    end
  end

  describe 'empty' do
    it 'create an empty instance' do
      HitAndBlow::Solver::Candidate::Digit.empty.should eq []
    end
  end

  describe 'setup using given numbers and weights' do
    ary = [[0, 10.0], [3, 20.0], [9, 15.0]]
    it 'create an instance that has a set of given numbers and weights' do
      HitAndBlow::Solver::Candidate::Digit.setup(ary).should eq ary
    end
  end

  describe 'setup using given numbers(without weight)' do
    ary = [0, 3, 9]
    it 'create an instance that has a set of given numbers with equal weight' do
      HitAndBlow::Solver::Candidate::Digit.setup(ary).should eq ary.map { |v| [v, 100.0] }
    end

    it 'throw un-given numbers into the trashbox' do
      digit = HitAndBlow::Solver::Candidate::Digit.setup(ary)
      digit.trashbox.should eq ((0..9).to_a - ary)
    end
  end

  context 'when default' do
    subject do
      @weight = 100.0
      digit = HitAndBlow::Solver::Candidate::Digit.default(@weight)
    end

    describe 'number_at(0)' do
      it 'should eq 0' do
        subject.number_at(0).should eq 0
      end
    end

    describe 'number_at(2)' do
      it 'should eq 2' do
        subject.number_at(2).should eq 2
      end
    end

    describe 'number_at(9)' do
      it 'should eq 9' do
        subject.number_at(9).should eq 9
      end
    end

    describe 'number_at(10)' do
      it 'should be nil' do
        subject.number_at(10).should be_nil
      end
    end

    describe 'weight_of(0)' do
      it 'should eq 100.0' do
        subject.weight_of(0).should eq 100.0
      end
    end

    describe 'weight_of(10)' do
      it 'should be nil' do
        subject.weight_of(10).should be_nil
      end
    end

    describe 'weight_at(0)' do
      it 'should eq 100.0' do
        subject.weight_at(0).should eq 100.0
      end
    end

    describe 'weight_at(10)' do
      it 'should be nil' do
        subject.weight_at(10).should be_nil
      end
    end
    
    describe 'numbers' do
      it 'should eq all of 0-9' do
        subject.numbers.should eq [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      end
    end

    describe 'include?(0)' do
      it 'should be true' do
        subject.include?(0).should be_true
      end
    end

    describe 'include?(10)' do
      it 'should be false' do
        subject.include?(10).should be_false
      end
    end

    describe 'has_trash?' do
      it 'should be false' do
        subject.has_trash?.should be_false
      end
    end

    describe 'pick_up_trash' do
      it 'should be nil' do
        subject.pick_up_trash.should be_nil
      end
    end

    describe 'exclude([0, 2, 3, 5, 7, 8])' do
      it "should eq [[1, #{@weight}], [4, #{@weight}], [6, #{@weight}], [9, #{@weight}]]" do
        subject.exclude([0, 2, 3, 5, 7, 8]).should eq [[1, @weight], [4, @weight], [6, @weight], [9, @weight]]
      end
    end

    describe 'remove' do
      it 'remove given numbers' do
        subject.remove 0
        subject.numbers.should eq [1, 2, 3, 4, 5, 6, 7, 8, 9]
        subject.remove 9
        subject.numbers.should eq [1, 2, 3, 4, 5, 6, 7, 8]
        subject.remove 0
        subject.numbers.should eq [1, 2, 3, 4, 5, 6, 7, 8]
        subject.remove 2, 4
        subject.numbers.should eq [1, 3, 5, 6, 7, 8]
        subject.remove 0, 5
        subject.numbers.should eq [1, 3, 6, 7, 8]
      end
    end

    context 'when some numbers removed' do
      before :each do
        subject.remove(0)
        subject.remove(2)
        subject.remove(5)
      end

      describe 'numbers' do
        it 'should eq 0-9 without removed numbers' do
          subject.numbers.should eq [1, 3, 4, 6, 7, 8, 9]
        end
      end

      describe 'has_trash?' do
        it 'should be true' do
          subject.has_trash?.should be_true
        end
      end

      describe 'trashes' do
        it 'should eq [0, 9, 2, 4, 5]' do
          subject.trashes.should eq [0, 2, 5]
        end
      end

      describe 'pick_up_trash' do
        it "should eq 0" do
          subject.pick_up_trash.should eq 0
        end
      end

      describe 'pick_up_trash(0)' do
        it "should eq 2" do
          subject.pick_up_trash(0).should eq 2
        end
      end

      describe 'pick_up_trash(0,2)' do
        it "should eq 5" do
          subject.pick_up_trash(0,2).should eq 5
        end
      end

      describe '==' do
        it 'should be true if two digits are equal' do
          other = HitAndBlow::Solver::Candidate::Digit.setup([1, 3, 4, 6, 7, 8, 9])
          subject.should eq other
        end
      end
    end

    describe 'add_weight' do
      before :each do
        subject.add_weight 0,  20.0
        subject.add_weight 2,  10.0
        subject.add_weight 5, 100.0
      end

      it 'should add the value to weight of the number' do
        subject.weight_of(0).should eq 120.0
        subject.weight_of(2).should eq 110.0
        subject.weight_of(5).should eq 200.0
      end
    end

    describe 'pick_at_random' do
      it 'should return a random 1-digit-number' do
        subject.pick_at_random.should be >= 0
        subject.pick_at_random.should be <= 9
      end
    end
  end
end
