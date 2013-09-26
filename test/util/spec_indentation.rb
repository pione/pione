require 'pione/test-helper'

TEXT = []
EXPECT = []

# case 0
TEXT.push <<S
  1st line
  2nd line
  3rd line
S

EXPECT.push <<S
1st line
2nd line
3rd line
S

# case 1
TEXT.push <<S
  1st line
    2nd line
      3rd line
S

EXPECT.push <<S
1st line
  2nd line
    3rd line
S

# case 2
TEXT.push <<S
    1st line
  2nd line
3rd line
S

EXPECT.push <<S
1st line
2nd line
3rd line
S

# case 3
TEXT.push <<S
    1st line
  2nd line
    3rd line
S

EXPECT.push <<S
1st line
2nd line
3rd line
S

# case 4
TEXT.push <<S
    1st line
    2nd line
  3rd line
S

EXPECT.push <<S
1st line
2nd line
3rd line
S

describe "Pione::Util::Indentaion" do
  TEXT.size.times do |i|
    it 'should cut indendations: case %s' % i do
      Util::Indentation.cut(TEXT[i]).should == EXPECT[i]
    end
  end
end
