#!/usr/bin/ruby

require 'thread'
require 'logger'

TEMP_THRESHOLD  = 40.0 # Celsius
NET_THRESHOLD   = 1    # MB/s

USBRH_TEMP_PATH = '/proc/usbrh/1/temperature'
NAS_HOST_LIST   = ['columbia', 'costarica', 'ethiopia']
SWITCH_NAME     = 'Server FAN Switch'

WEMO_PATH       = '/usr/local/bin/wemo'

INTERVAL        = 60
LATENCY         = [2, 120] # OFF->ON, ON->OFF
MAX_THREAD      = 2

LOGGER = Logger.new('/var/log/auto_server_fan/auto_server_fan.log')
LOGGER.level = Logger::INFO

def conv_unit_megabyte(number, unit)
  case unit
  when "M" then
    return number.to_i
  when "k" then
    return number.to_i / 1024
  when "B" then
    return number.to_i / 1024 /1024
  else
    reutrn 0
  end
end

def check_network_usage_host(host, th)
  result = `ssh #{host} 'sudo dstat --net 1 1 | tail -n 1'`

  LOGGER.debug "network usage[#{host}]: #{result}"

  if result.match(/(\d+)([MkB])\s+(\d+)([MkB])/) then
    recv = conv_unit_megabyte($1, $2)
    send = conv_unit_megabyte($3, $4)
    return (recv  > th) || (send  > th)
  else
    return false
  end
end

def check_network_usage(host_list, th)
  thread_list = []
  locker = Mutex::new
  host_queue = host_list.dup

  MAX_THREAD.times do |i|
    thread_list << Thread.start {
      result = false
      loop do
        host = locker.synchronize { host_queue.pop }
        break unless host
        result |= check_network_usage_host(host, th)
      end
      Thread.current[:output] = result
    }
  end
  result = false;
  thread_list.each do |thread|
    thread.join
    result |= thread[:output]
  end
  return result
end

def check_temperature(temp_path, th)
  result = `cat #{temp_path}`

  LOGGER.debug "temperature: #{result}"

  return result.to_f > th
end

def control_fan(switch_name, state)
  mode = state ? 'on' : 'off'
  result = `#{WEMO_PATH} --no-cache switch '#{switch_name}' #{mode}`
  LOGGER.debug "#{WEMO_PATH} --no-cache switch '#{switch_name}' #{mode}"
  LOGGER.debug "result: #{result}"
  LOGGER.info "control fan: #{mode}"
end

count = 0
state = 0 # 0: OFF, 1: ON
control_fan(SWITCH_NAME, false)

loop do
  shall_on = false
  shall_on |= check_temperature(USBRH_TEMP_PATH, TEMP_THRESHOLD)
  shall_on |= check_network_usage(NAS_HOST_LIST, NET_THRESHOLD)

  incr = [ 1, -1 ]
  incr.reverse! if (state != 0)

  count += (shall_on ? incr[0] : incr[1])
  count = 0 if count < 0

  LOGGER.debug "state: #{state}, count: #{count}, shall_on: #{shall_on}"

  if (count > LATENCY[state]) then
    state = (state == 0) ? 1 : 0
    control_fan(SWITCH_NAME, state == 1)
    count = 0;
  elsif (rand(60) == 0) then
    # faile safe
    control_fan(SWITCH_NAME, state == 1)
  end

  sleep(INTERVAL)
end
