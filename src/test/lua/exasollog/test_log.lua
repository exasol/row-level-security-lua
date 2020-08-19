local luaunit = require("luaunit")
local mockagne = require("mockagne")

local when, verify, any = mockagne.when, mockagne.verify, mockagne.any

local date_pattern = "%Y-%m-%d"

test_log = {}

function test_log:setUp()
    self.today = os.date(date_pattern)
    self.socket_mock = mockagne.getMock()
    self.client_mock = mockagne.getMock()
    when(self.socket_mock.connect(any(), any())).thenAnswer(self.client_mock)
    when(self.socket_mock.gettime()).thenAnswer(1000000)
    package.preload["socket"] = function () return self.socket_mock end
    self.log = require("exasollog.log").init(date_pattern, false)
    self.log.open()
end

function test_log:tearDown()
    self.log.close()
    package.loaded["socket"] = nil
    package.loaded["exasollog.log"] = nil
end

function test_log:assert_message(message)
    verify(self.client_mock:send(message))
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
    self.log.config("Life support enabled.")
    self:assert_message(self.today .. " [CONFIG] Life support enabled.\n")
end

function test_log:test_debug()
    self.log.debug("Look what we have here.")
    self:assert_message(self.today .. " [DEBUG]  Look what we have here.\n")
end

function test_log:test_trace()
    self.log.trace("foo(bar)")
    self:assert_message(self.today .. " [TRACE]  foo(bar)\n")
end

os.exit(luaunit.LuaUnit.run())