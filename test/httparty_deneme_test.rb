require_relative '../httparty_deneme'

class HttpartyDenemeTest
  attr_accessor :result_h

  def initialize(thread_count)
    @result_h = {}
    @thread_count = thread_count - 1
  end

  def test_threads
    @result_h = {}

    0.upto(@thread_count) { |i|
      Thread.new do
        ht = HttpartyDeneme.new
        random_node = rand(100)
        response = ht.execute_script("g.v(#{random_node}).out.out.out.out")
        @result_h[Thread.current.inspect] = response
      end

      puts "#{i} started"
    }

    puts "Waiting all threads to finish"
    Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
    puts "All threads should have been finished"

    puts @result_h.size
  end
end

#t = HttpartyDenemeTest.new 0
#t.test_threads

