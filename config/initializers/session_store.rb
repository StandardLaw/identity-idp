require 'idle_session_expiration_store'

options = {
  key: '_upaya_session',
  redis: {
    driver: :hiredis,
    expire_after: Figaro.env.session_timeout_in!.to_i.minutes,
    key_prefix: "#{Figaro.env.domain_name!}:session:",
    url: Figaro.env.redis_url!
  },
  # on_redis_down: ->(e, env, sid) { do_something_will_ya!(e) },
  # on_session_load_error: ->(e, sid) { do_something_will_ya!(e) },
  serializer: :marshal
}
Rails.application.config.session_store :idle_session_expiration_store, options
