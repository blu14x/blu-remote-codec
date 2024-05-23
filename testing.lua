assertTrue        = function(value)
  if not value then error('Result value is not true', 2) end
end
assertFalse       = function(value)
  if value then error('Result value is not false', 2) end
end
assertEqual       = function(expected, actual)
  if actual ~= expected then
    local message = string.format('Expected & actual values are not equal:\nExpected: %s\nActual:   %s', val.toString(expected), val.toString(actual))
    error(message, 2)
  end
end
assertTableEqual  = function(expected, actual)
  local isEqual = true
  for k, v in pairs(expected) do
    if type(v) == 'table' then
      if not assertTableEqual(v, actual[k]) then
        isEqual = false
        break
      end
    elseif actual[k] ~= v then
      isEqual = false
      break
    end
  end
  for k, v in pairs(actual) do
    if type(v) == 'table' then
      if not assertTableEqual(v, expected[k]) then
        isEqual = false
        break
      end
    elseif expected[k] ~= v then
      isEqual = false
      break
    end
  end
  if not isEqual then error('Expected & actual tables are not equal', 2) end
  return isEqual
end
assertError       = function(callback, expectedErrorMessage)
  local status, err = pcall(callback)
  if status then error("Function call was expected to fail, but it didn't", 2) end

  if err:sub(-#expectedErrorMessage) ~= expectedErrorMessage then
    local message = string.format('Received error message does not match expectation:\nReceived (may include location): "%s"\nExpected: "%s"', tostring(err), tostring(expectedErrorMessage))
    error(message, 2)
  end
end

TestEntry         = {}
TestEntry.__index = TestEntry
function TestEntry:new(name, func)
  local instance = setmetatable({}, TestEntry)
  instance.name  = name or 'Unnamed Test Entry'
  instance.func  = func
  return instance
end

TestCase         = {}
TestCase.__index = TestCase
function TestCase:new(name, tests)
  local instance   = setmetatable({}, TestCase)
  instance.name    = name or 'Unnamed Test Case'
  instance.tests   = tests
  instance.results = { succeeded = {}, failed = {} }
  return instance
end
function TestCase:run()
  self.results = { succeeded = {}, failed = {} }
  for _, test in ipairs(self.tests) do
    local status, errorMessage = pcall(test.func)
    local resultTable          = status and self.results.succeeded or self.results.failed
    table.insert(resultTable, { name = test.name, errorMessage = errorMessage })
  end
  self:report()
end
function TestCase:report()
  local nameStr    = string.format('TestCase: "%s"', self.name)
  local resultsStr = string.format('%2s/%2s passed  (%s failed)', #self.results.succeeded, #self.tests, #self.results.failed)

  print(string.format('%-25s - %s', nameStr, resultsStr))

  for _, failedTest in ipairs(self.results.failed) do
    local testStr = string.format('"%s"', failedTest.name)
    print(string.format('[FAIL] %s: %s', testStr, failedTest.errorMessage))
  end
  if #self.results.failed > 0 then print("") end
end

TestCluster         = {}
TestCluster.__index = TestCluster
function TestCluster:new(name, cases)
  local instance = setmetatable({}, TestCluster)
  instance.name  = name or 'Unnamed Test Cluster'
  instance.cases = cases
  return instance
end
function TestCluster:run()
  print(string.format('\nStarting Test Cluster: "%s"', self.name))
  for _, case in ipairs(self.cases) do
    case:run()
  end
end
