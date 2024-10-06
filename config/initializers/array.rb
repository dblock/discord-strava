class Array
  def and(&)
    join_with('and', &)
  end

  def or(&)
    join_with('or', &)
  end

  private

  def join_with(separator, &)
    if count > 1
      "#{self[0..-2].map { |i| apply(i, &) }.join(', ')} #{separator} #{apply(self[-1], &)}"
    else
      apply(first, &)
    end
  end

  def apply(item, &block)
    block ? block.call(item) : item
  end
end
