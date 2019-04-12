context("test-metadata")

test_that("metadata_string", {
  value_test='This is a test value'
  set_metadata_value('test_string',value_test)
  res=get_metadata_value('test_string')
  clean_metadata_value('test_string')
  expect_equal(value_test, res)
})

test_that("metadata_integer", {
  value_test=as.integer(-131)
  set_metadata_value('test_integer',value_test)
  res=get_metadata_value('test_integer')
  clean_metadata_value('test_integer')
  expect_equal(value_test, res)
})

test_that("metadata_numeric", {
  value_test=as.numeric(1.3)
  set_metadata_value('test_numeric',value_test)
  res=get_metadata_value('test_numeric')
  clean_metadata_value('test_numeric')
  expect_equal(value_test, res)
})

test_that("metadata_date", {
  value_test=as.Date('2018-04-01')
  set_metadata_value('test_date',value_test)
  res=get_metadata_value('test_date')
  clean_metadata_value('test_date')
  expect_equal(value_test, res)
})

test_that("metadata_timestamp", {
  value_test=as.POSIXct('2018-04-01 13:00:00')
  set_metadata_value('test_timestamp',value_test)
  res=get_metadata_value('test_timestamp')
  clean_metadata_value('test_timestamp')
  expect_equal(value_test, res)
})



test_that("metadata_string_local", {
  value_test='This is a test value'
  set_metadata_value('test_string',value_test, source='/tmp/test.rds')
  res=get_metadata_value('test_string', source='/tmp/test.rds')
  file.remove('/tmp/test.rds')
  expect_equal(value_test, res)
})

test_that("metadata_integer_local", {
  value_test=as.integer(-131)
  set_metadata_value('test_integer',value_test, source='/tmp/test.rds')
  res=get_metadata_value('test_integer', source='/tmp/test.rds')
  file.remove('/tmp/test.rds')
  expect_equal(value_test, res)
})

test_that("metadata_numeric_local", {
  value_test=as.numeric(1.3)
  set_metadata_value('test_numeric',value_test, source='/tmp/test.rds')
  res=get_metadata_value('test_numeric', source='/tmp/test.rds')
  file.remove('/tmp/test.rds')
  expect_equal(value_test, res)
})

test_that("metadata_date_local", {
  value_test=as.Date('2018-04-01')
  set_metadata_value('test_date',value_test, source='/tmp/test.rds')
  res=get_metadata_value('test_date', source='/tmp/test.rds')
  file.remove('/tmp/test.rds')
  expect_equal(value_test, res)
})

test_that("metadata_timestamp_local", {
  value_test=as.POSIXct('2018-04-01 13:00:00')
  set_metadata_value('test_timestamp',value_test, source='/tmp/test.rds')
  res=get_metadata_value('test_timestamp', source='/tmp/test.rds')
  file.remove('/tmp/test.rds')
  expect_equal(value_test, res)
})
