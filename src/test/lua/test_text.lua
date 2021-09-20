local luaunit = require("luaunit")
local text = require("text")

test_text = {}

function test_text.test_trim()
    luaunit.assertEquals(text.trim("  the text   "), "the text")
end

function test_text.test_split()
    local tests ={
        {
            {input = "foo,bar,baz", expected = {"foo", "bar", "baz"}},
            {input = "foo,,bar,baz", expected = {"foo", "bar", "baz"}},
            {input = ",1,2,3", expected = {"1", "2", "3"}},
            {input = " Hello , world    , ! ", expected = {"Hello", "world", "!"}},
            {input = "", expected = {}},
            {input = nil, expected = {}}
        }
    }
    for _, test in ipairs(tests) do
        luaunit.assertEquals(text.split(test.input), test.expected)
    end
end

os.exit(luaunit.LuaUnit.run())