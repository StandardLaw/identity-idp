require 'redis-session-store'

class IdleSessionExpirationStore < RedisSessionStore
  def get_session(env, sid)
    super.tap { update_session_ttl(sid) }
  end

  def update_session_ttl(sid)
    expiry = @default_options[:expire_after]
    @redis.expire(prefixed(sid), expiry)
  rescue Errno::ECONNREFUSED, Redis::CannotConnectError => error
    on_redis_down.call(error, env, sid) if on_redis_down
    return false
  end
end
