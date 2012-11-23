require "redis"
require_relative 'tez_tester'
require_relative 'configuration'

class TezTesterRunner
  attr_accessor :result_h

  def initialize(thread_count)
    @logger             ||= Logger.new(STDOUT)
    @logger.level         = Logger::INFO

    @logger_to_file     ||= Logger.new(Configuration::LOG_FILE)
    @logger_to_file.level = Logger::DEBUG

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

    if i_should_run?
      #ec2_instance_id = `wget -qO- instance-data/latest/meta-data/instance-id`
      ec2_instance_id = "asdf"

      fire_gremlin_threads(ec2_instance_id, gid, port, title_for_log)

      @logger.debug "#{title_for_log} Waiting all threads to finish"
      #Does not come to end while debuggin becuase of the debug thread. join(seconds_to_wait) could be used.
      Thread.list.each { |t| t.join unless t == Thread.main or t == Thread.current }
      @logger.debug "#{title_for_log} All threads should have been finished, thread count: #{@result_h.size}"

      @logger.info Time.now - start
    else
      @logger.info "RUN value in REDIS is not 1"
    end
  end

  def i_should_run?
    result = @redis.get("RUN").eql? "1"
  end

  def fire_gremlin_threads(ec2_instance_id, gid, port, title_for_log)
    0.upto(@thread_count) { |thread_idx|
      Thread.new do
        tez_tester = TezTester.new
        begin
          result = tez_tester.for_hubway(gid, port)
          @logger.info "#{title_for_log} results_from_partitioned.size = #{result.size}, Thread: #{thread_idx}"
          @result_h[Thread.current.inspect] = result
          @redis.rpush("CALISTI", "#{ec2_instance_id} # Thread: #{thread_idx} # #{Time.now}")
        rescue
          @logger.debug "CAKILDI#Thread:#{thread_idx}"
          @redis.rpush("CAKILDI", "#{ec2_instance_id} # Thread: #{thread_idx} # #{Time.now}")
        end
      end

      @logger.debug "#{title_for_log} #{thread_idx} started"
    }
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

t = TezTesterRunner.new Configuration::THREAD_COUNT
#args = ARGV
#hash = Hash[*args]
#t.cypher_partitioning(12, hash["port"], hash["port"])
t.cypher_partitioning(Configuration::GID, Configuration::PORT, Configuration::PORT)