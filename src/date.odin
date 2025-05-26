package dn

import "core:testing"
import "core:time"

copy_date :: proc(t: time.Time, buf: []byte, sep: byte) {
	assert(len(buf) >= time.MIN_YYYY_DATE_LEN)

	year, _month, day := time.date(t)
	month := u8(_month)

	buf[9] = '0' + u8(day % 10);day /= 10
	buf[8] = '0' + u8(day % 10)
	buf[7] = sep
	buf[6] = '0' + u8(month % 10);month /= 10
	buf[5] = '0' + u8(month % 10)
	buf[4] = sep
	buf[3] = '0' + u8(year % 10);year /= 10
	buf[2] = '0' + u8(year % 10);year /= 10
	buf[1] = '0' + u8(year % 10);year /= 10
	buf[0] = '0' + u8(year)
}

@(test)
test_copy_date :: proc(t: ^testing.T) {
	expect_buf: [10]byte
	buf: [10]byte

	now := time.now()

	time.to_string_yyyy_mm_dd(now, expect_buf[:])
	copy_date(now, buf[:], '-')

	testing.expect(t, string(expect_buf[:]) == string(buf[:]))
}
