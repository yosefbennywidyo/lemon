
class Example

  def f(x,y)
    x + y
  end
  
end

TestCase Example do

  unit :f => "one and one is two"do
    Example.new.f(1,1).assert == 2
  end

  unit :f do
    ex = Example.new
    ex.f(1,2).assert == 4
  end

end

