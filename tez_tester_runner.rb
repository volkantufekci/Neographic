require "redis"
require_relative 'tez_tester'
require_relative 'configuration'

class TezTesterRunner
  attr_accessor :result_h

  def initialize(thread_count)
    @logger ||= Logger.new(STDOUT)
    @logger.level=Logger::INFO

    @logger_to_file ||= Logger.new("logv.txt")
    @logger_to_file.level=Logger::DEBUG

    @thread_count = thread_count - 1
    @redis = Redis.new({:host => Configuration::REDIS_URL, :port => 6379})
  end

  def test_threaded_partitioning
    @logger.info "Same gid for every thread"
    gid = rand(1..1000)
    threaded_partitioning(gid, "partitioned") { |ht, gid, out_count| ht.analyze(gid, out_count) }
    threaded_partitioning(gid, "NONpartitioned") { |ht, gid, out_count| ht.execute_on_valid_partition(gid, out_count) }

    puts "\n"

    @logger.info "Random gid for every thread"
    threaded_partitioning(nil, "partitioned") { |ht, gid, out_count| ht.analyze(gid, out_count) }
    threaded_partitioning(nil, "NONpartitioned") { |ht, gid, out_count| ht.execute_on_valid_partition(gid, out_count) }
  end


  def cypher_partitioning(gid, title_for_log, port)
    start = Time.now
    @result_h = {}

    0.upto(@thread_count) { |i|
      Thread.new do
        tez_tester = TezTester.new
        @logger.debug "#{title_for_log} random gid: #{gid}"

        begin
          result = tez_tester.for_hubway(gid, port)
          @logger.info "#{title_for_log} results_from_partitioned.size = #{result.size}, Thread: #{i}"
          @result_h[Thread.current.inspect] = result
        rescue
          @logger.debug "CAKILDI#Thread:#{i}"
          ec2_instance_id = `wget -qO- instance-data/latest/meta-data/instance-id`
          @redis.rpush("CAKILDI", ec2_instance_id)
        end
      end

      @logger.debug "#{title_for_log} #{i} started"
    }

    @logger.debug "#{title_for_log} Waiting all threads to finish"

    #Does not come to end while debuggin becuase of the debug thread. join(seconds_to_wait) could be used.
    Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
    @logger.debug "#{title_for_log} All threads should have been finished"

    @logger.debug "#{title_for_log} thread count: #{@result_h.size}"
    @logger.info Time.now - start
  end

  private

  def threaded_partitioning(gid_param, title_for_log)
    start = Time.now
    @result_h = {}

    0.upto(@thread_count) { |i|
      Thread.new do
        ht = TezTester.new
        out_count = 5
        if gid_param
          gid = gid_param
        else
          gid = rand(1..1000)
        end
        @logger.debug "#{title_for_log} random gid: #{gid}"

        result = ht.filter_intermediate_paths(out_count, yield(ht, gid, out_count))
        @logger.debug "#{title_for_log} results_from_partitioned.size = #{result.size}"
        log_to_file(result)

        @result_h[Thread.current.inspect] = result
      end

      @logger.debug "#{title_for_log} #{i} started"
    }

    @logger.info "#{title_for_log} Waiting all threads to finish"

    #Does not come to end while debuggin becuase of the debug thread. join(seconds_to_wait) could be used.
    Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
    @logger.info "#{title_for_log} All threads should have been finished"

    @logger.debug "#{title_for_log} thread count: #{@result_h.size}"
    @logger.info Time.now - start
  end

  def log_to_file(result_a)
    message = "\n"
    result_a.each { |array| message << "#{array}\n" }
    @logger_to_file.debug message
  end
end

#t = TezTesterRunner.new 2
#t.test_threaded_partitioning
t = TezTesterRunner.new 1
#t.cypher_partitioning(1, "7474", 7474)
args = ARGV
hash = Hash[*args]
t.cypher_partitioning(12, hash["port"], hash["port"])




