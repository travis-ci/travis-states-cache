RSpec::Matchers.define :call do |obj, method|
  match do |subject|
    expectation = obj.expects(method)
    expectation = expectation.never if @never
    expectation = expectation.with(*@args) if @args
    subject.call
    true
  end

  def never
    @never = true
    self
  end

  def with(*args)
    @args = args
    self
  end

  def supports_block_expectations?
    true
  end
end

RSpec::Matchers.define :log do |line|
  match do |subject|
    subject.call
    line.is_a?(Regexp) ? line =~ stdout : stdout.include?(line)
  end

  failure_message do
    "expected the log\n\n    #{stdout.inspect}\n\nto match\n\n    #{line.inspect}"
  end

  def supports_block_expectations?
    true
  end
end
