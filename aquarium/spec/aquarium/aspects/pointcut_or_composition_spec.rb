require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../spec_example_classes'
require 'aquarium/utils'
require 'aquarium/extensions'
require 'aquarium/aspects/pointcut'
require 'aquarium/aspects/pointcut_composition'

include Aquarium::Utils::HashUtils
include Aquarium::Aspects

describe "Union of Pointcuts", :shared => true do
  
  before(:each) do
    classes = [
      ClassWithProtectedInstanceMethod, 
      ClassWithPrivateInstanceMethod, 
      ClassWithPublicClassMethod, 
      ClassWithPrivateClassMethod,
      ClassIncludingModuleWithPrivateClassMethod, 
      ClassIncludingModuleWithPublicClassMethod,
      ClassIncludingModuleWithProtectedInstanceMethod, 
      ClassIncludingModuleWithPrivateInstanceMethod]
    jps_array = classes.map {|c| Aquarium::Aspects::JoinPoint.new :type => c, :method => :all}
    @not_matched_jps = Set.new(jps_array)
  end

  it "should return a Pointcut equal to the second, appended, non-empty Pointcut if self is empty (has no join points)." do
    pc1 = Pointcut.new
    pc2 = Pointcut.new :types => /Class.*Method/
    pc1.or(pc2).should eql(pc2)
    pc3 = Pointcut.new :object => ClassWithPublicInstanceMethod.new
    pc1.or(pc3).should eql(pc3)
  end
   
  it "should return a Pointcut equal to self if the second pointcut is empty." do
    pc1 = Pointcut.new :types => /Class.*Method/
    pc2 = Pointcut.new
    pc1.or(pc2).should eql(pc1)
    pc3 = Pointcut.new :object => ClassWithPublicInstanceMethod.new
    pc3.or(pc2).should eql(pc3)
  end
   
  it "should return a new Pointcut whose join points are the union of the left- and right-hand side Pointcuts for type-based Pointcuts." do
    pc1 = Pointcut.new :types => ClassWithAttribs, :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    # "[^F]" excludes the ClassWithFunkyMethodNames ...
    pc2 = Pointcut.new :types => [/ClassWith[^F]+Method/, /ClassDerived/, /ClassIncludingMod/], :method_options => :exclude_ancestor_methods
    pc = pc1.or pc2
    jp1 = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method => :attrRW_ClassWithAttribs=
    jp2 = Aquarium::Aspects::JoinPoint.new :type => ClassWithAttribs, :method => :attrW_ClassWithAttribs=
    jp3 = Aquarium::Aspects::JoinPoint.new :type => ClassWithPublicInstanceMethod,  :method => :public_instance_test_method
    jp4 = Aquarium::Aspects::JoinPoint.new :type => ClassWithPublicInstanceMethod2, :method => :public_instance_test_method2
    jp5 = Aquarium::Aspects::JoinPoint.new :type => ClassDerivedFromClassIncludingModuleWithPublicInstanceMethod, :method => :public_instance_class_derived_from_class_including_module_test_method
    jp6 = Aquarium::Aspects::JoinPoint.new :type => ClassIncludingModuleWithPublicInstanceMethod, :method => :public_instance_class_including_module_test_method
    pc.join_points_matched.should == Set.new([jp1, jp2, jp3, jp4, jp5, jp6])
    pc.join_points_not_matched.should == @not_matched_jps
  end
   
  it "should return a new Pointcut whose join points are the union of the left- and right-hand side Pointcuts for object-based Pointcuts." do
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new
    pc1 = Pointcut.new :objects => [cwa], :attributes => [/^attr/], :attribute_options => [:writers, :exclude_ancestor_methods]
    pc2 = Pointcut.new :object  => pub, :method_options => :exclude_ancestor_methods
    pc = pc1.or pc2
    jp1 = Aquarium::Aspects::JoinPoint.new :object => cwa, :method => :attrRW_ClassWithAttribs=
    jp2 = Aquarium::Aspects::JoinPoint.new :object => cwa, :method => :attrW_ClassWithAttribs=
    jp3 = Aquarium::Aspects::JoinPoint.new :object => pub, :method => :public_instance_test_method
    pc.join_points_matched.sort.should == [jp1, jp2, jp3].sort
    pc.join_points_not_matched.sort.should == []
  end
   
  it "should be unitary for type-based Pointcuts." do 
    pc1 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers]
    pc = pc1.or pc2
    pc.should eql(pc1)
    pc.should eql(pc2)
  end
   
  it "should be unitary for object-based Pointcuts." do 
    cwa = ClassWithAttribs.new
    pc1 = Pointcut.new :object => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :object => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc = pc1.or pc2
    pc.should eql(pc1)
    pc.should eql(pc2)
  end
   
  it "should be commutative for type-based Pointcuts." do 
    pc1 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :types => /Class.*Method/
    pc12 = pc1.or pc2
    pc21 = pc2.or pc1
    pc12.should eql(pc21)
  end
   
  it "should be commutative for object-based Pointcuts." do 
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pc1 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :objects => pub, :attributes => [/^attr/], :attribute_options => [:writers]
    pc12 = pc1.or pc2
    pc21 = pc2.or pc1
    pc12.should eql(pc21)
  end
   
  it "should be associativity for type-based Pointcuts." do 
    pc1 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Pointcut.new :types => /Class.*Method/
    pc123a = (pc1.or(pc2)).or(pc3)
    pc123b = pc1.or(pc2.or(pc3))
    pc123a.should eql(pc123b)
  end
   
  it "should be associativity for object-based Pointcuts." do 
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pc1 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Pointcut.new :objects => pub
    pc123a = (pc1.or(pc2)).or(pc3)
    pc123b = pc1.or(pc2.or(pc3))
    pc123a.should eql(pc123b)
  end

end

describe Pointcut, "#or" do
  it_should_behave_like "Union of Pointcuts"
end

describe Pointcut, "#|" do
 
  it_should_behave_like "Union of Pointcuts"

  it "should be associativity for type-based Pointcuts." do 
    pc1 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :types => "ClassWithAttribs", :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Pointcut.new :types => /Class.*Method/
    pc123a = (pc1 | pc2) | pc3
    pc123b = pc1 | (pc2 | pc3)
    pc123a.should eql(pc123b)
  end
   
  it "should be associativity for object-based Pointcuts." do 
    cwa = ClassWithAttribs.new
    pub = ClassWithPublicInstanceMethod.new 
    pc1 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:writers]
    pc2 = Pointcut.new :objects => cwa, :attributes => [/^attr/], :attribute_options => [:readers]
    pc3 = Pointcut.new :objects => pub
    pc123a = (pc1 | pc2) | pc3
    pc123b = pc1 | (pc2 | pc3)
    pc123a.should eql(pc123b)
  end
end