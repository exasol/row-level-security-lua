local luaunit = require("luaunit")
local mockagne = require("mockagne")

local when, verify, any = mockagne.when, mockagne.verify, mockagne.any
local date_pattern = "%Y-%m-%d"

test_log = {}

function test_log:setUp()
    self.today = os.date(date_pattern)
    self.socket_mock = mockagne.getMock()
    self.tcp_mock = mockagne.getMock()
    self.client_mock = self.tcp_mock -- on connect(), the socket library promotes a TCP socket to a client socket
    when(self.socket_mock.tcp()).thenAnswer(self.tcp_mock)
    when(self.tcp_mock:connect(any(), any())).thenAnswer(1)
    when(self.socket_mock.gettime()).thenAnswer(1000000)
    package.preload["socket"] = function () return self.socket_mock end
    self.log = require("exasollog.log").init(date_pattern, false)
    self.log.set_client_name("Unit test")
    self.log.connect("localhost", 3000)
end

function test_log:tearDown()
    self.log.disconnect()
    package.loaded["socket"] = nil
    package.loaded["exasollog.log"] = nil
end

function test_log:assert_message(message)
    verify(self.client_mock:send(message))
end

function test_log:assert_no_message(message)
    luaunit.assertErrorMsgContains("no invocation made", function() self:assert_message(message) end)
end

function test_log:test_startup_message()
    local timezone = os.date("%z")
    self:assert_message(self.today .. " [INFO]   Unit test: Connected to log receiver listening on localhost:3000"
        .. " with log level INFO. Timezone is UTC" .. timezone .. ".\n")
end

function test_log:test_fatal()
    self.log.fatal("Good by, cruel world!")
    self:assert_message(self.today .. " [FATAL]  Good by, cruel world!\n")
end

function test_log:test_error()
    self.log.error("Oops!")
    self:assert_message(self.today .. " [ERROR]  Oops!\n")
end

function test_log:test_warn()
    self.log.warn("This looks suspicious...")
    self:assert_message(self.today .. " [WARN]   This looks suspicious...\n")
end

function test_log:test_info()
    self.log.info("Good to know.")
    self:assert_message(self.today .. " [INFO]   Good to know.\n")
end

function test_log:test_config()
    self.log.set_level("CONFIG")
    self.log.config("Life support enabled.")
    self:assert_message(self.today .. " [CONFIG] Life support enabled.\n")
end

function test_log:test_debug()
    self.log.set_level("DEBUG")
    self.log.debug("Look what we have here.")
    self:assert_message(self.today .. " [DEBUG]  Look what we have here.\n")
end

function test_log:test_trace()
    self.log.set_level("TRACE")
    self.log.trace("foo(bar)")
    self:assert_message(self.today .. " [TRACE]  foo(bar)\n")
end

function test_log:test_set_log_level()
    self.log.set_level("WARN")
    self.log.info("don't send")
    self.log.warn("send")
    self:assert_message(self.today .. " [WARN]   send\n")
    self:assert_no_message(self.today .. " [INFO]   don't send\n")
end

function test_log:test_logging_with_format_string()
    self.log.info('%s says "Mount Everest is %d meters high."', "Simon", 8848)
    self:assert_message(self.today .. ' [INFO]   Simon says "Mount Everest is 8848 meters high."\n')
end

os.exit(luaunit.LuaUnit.run())