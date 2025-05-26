package dn

import "core:fmt"
import "core:log"
import os "core:os/os2"
import "core:path/filepath"
import "core:strings"
import "core:testing"

Expand_Error :: enum {
	None,
	Empty_Path,
	Without_Separator,
	Invalid_Home,
}

expand_path :: proc(path: string, allocator := context.allocator) -> (string, Expand_Error) {
	if len(path) == 0 {
		return path, .Empty_Path
	}

	if path[0] != '~' {
		return path, .None
	}

	if len(path) > 1 && path[1] != filepath.SEPARATOR {
		return path, .Without_Separator
	}

	home_dir := os.get_env("HOME", allocator)
	if home_dir == "" {
		return path, .Invalid_Home
	}

	when ODIN_TEST {
		home_dir = strings.trim_right_null(home_dir)
	}

	expanded_path := filepath.join({home_dir, path[1:]}, allocator)

	return expanded_path, .None
}


@(test)
test_expand_path :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	path: string

	// Test empty path
	path = ""
	result, err := expand_path(path)
	testing.expect(t, err == .Empty_Path)
	testing.expect(t, result == path)

	// Test path without prefix
	path = "without_prefix"
	result, err = expand_path(path)
	testing.expect(t, err == .None)
	testing.expect(t, result == path)

	// Test path with prefix but without separator
	path = "~without_separator"
	result, err = expand_path(path)
	testing.expect(t, err == .Without_Separator)
	testing.expect(t, result == path)

	// Test with empty HOME environment variable
	previous_home_dir := os.get_env("HOME", context.allocator)
	defer {
		_ = os.set_env("HOME", previous_home_dir)
	}

	_ = os.set_env("HOME", "")
	path = "~/valid-path"

	result, err = expand_path(path)
	testing.expect(t, err == .Invalid_Home)
	testing.expect(t, result == path)

	// Test with valid HOME environment variable
	_ = os.set_env("HOME", "/home/user/")
	result, err = expand_path(path)
	testing.expect(t, err == .None)
	testing.expect(t, result == "/home/user/valid-path")
}
