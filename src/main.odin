package dn

import "core:c/libc"
import "core:flags"
import "core:fmt"
import "core:mem"
import os "core:os/os2"
import "core:path/filepath"
import "core:strings"
import "core:sys/posix"
import "core:time"

VERSION :: "v0.1.0"

DEFAULT_NOTES_DIR :: "~/notes"

ARENA_BUFFER: [mem.Megabyte]byte
PATH_BUFFER: [len("yyyy/mm/dd.md")]byte
NOTE_BUFFER: [len("# yyyy-mm-dd\n\n\n")]byte

CLI_Options :: struct {
	root_dir: string `usage:"The location of the notes. Defaults to ~/notes."`,
	editor:   string `usage:"The editor in which the notes will be opened."`,
	version:  bool `usage:"Displays the current version."`,
}

main :: proc() {
	arena: mem.Arena
	mem.arena_init(&arena, ARENA_BUFFER[:])
	arena_allocator := mem.arena_allocator(&arena)

	ok := false
	defer os.exit(0 if ok else 1)

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, arena_allocator)
		arena_allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintfln("===== %v allocations not freed: =====", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintfln("- %v bytes @ %v", entry.size, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	// All procedures will use the arena allocator.
	context.allocator = arena_allocator

	cli_options: CLI_Options
	flags.parse_or_exit(&cli_options, os.args, .Unix)

	ok = run(&cli_options)
	free_all(arena_allocator)
}

run :: proc(cli_options: ^CLI_Options) -> (ok: bool) {
	current_time := local_now()

	if cli_options.version {
		fmt.println(VERSION)
		return true
	}

	root_dir := get_root_dir(cli_options.root_dir) or_return

	// Generates the note path in the following format: '<root_dir>/yyyy/mm/dd.md'.
	copy_date(current_time, PATH_BUFFER[:], '/')
	copy(PATH_BUFFER[time.MIN_YYYY_DATE_LEN:], ".md")

	file_path := filepath.join({root_dir, string(PATH_BUFFER[:])})
	dir_path := string(file_path[:len(file_path) - 5])

	// To interact with the 'posix' package, we need to use cstrings.
	c_editor := get_editor(cli_options.editor) or_return
	c_path := strings.clone_to_cstring(file_path)

	when ODIN_DEBUG {
		debug_values(c_editor, c_path)
		return true
	}

	if os.is_file(file_path) {
		return open_editor(c_editor, c_path)
	}

	if !os.is_dir(dir_path) {
		if err := os.mkdir_all(dir_path); err != nil {
			fmt.eprintfln("failed to create dir '%s' (%s)", dir_path, err)
			return false
		}
	}

	// Generates the note title in the following format: '# yyyy-mm-dd'.
	copy(NOTE_BUFFER[:], "# ")
	copy(NOTE_BUFFER[12:], "\n\n\n")
	copy_date(current_time, NOTE_BUFFER[2:12], '-')

	err := os.write_entire_file(file_path, NOTE_BUFFER[:])
	if err != nil {
		fmt.eprintfln("failed to write file '%s' (%s)", file_path, err)
		return false
	}

	return open_editor(c_editor, c_path)
}

open_editor :: proc(editor, path: cstring) -> bool {
	when ODIN_DEBUG {
		return true
	}

	ret := posix.execlp(editor, editor, path, nil)
	fmt.eprintfln("could not execute: %v, %v", ret, posix.strerror(posix.errno()))
	return false
}

get_root_dir :: proc(cli_dir: string) -> (string, bool) {
	root_dir := cli_dir

	if root_dir == "" {root_dir = os.get_env("DAILY_NOTES_DIR", context.allocator)}
	if root_dir == "" {
		root_dir = DEFAULT_NOTES_DIR
		when ODIN_DEBUG {
			fmt.printfln("using default root dir '%s'", DEFAULT_NOTES_DIR)
		}
	}

	err: Expand_Error
	root_dir, err = expand_path(root_dir)
	if err != .None {
		fmt.eprintfln("failed to expand path '%s' (%s)", root_dir, err)
		return root_dir, false
	}

	return root_dir, true
}

get_editor :: proc(cli_editor: string) -> (cstring, bool) {
	editor := cli_editor

	if editor == "" {editor = os.get_env("EDITOR", context.allocator)}
	if editor == "" {
		fmt.eprintln("invalid editor ''")
		return "", false
	}

	return strings.clone_to_cstring(editor), true
}

// HACK: The current local time is being retrieved through libc.
local_now :: proc() -> time.Time {
	current_time := libc.time(nil)
	time_info := libc.localtime(&current_time)

	local_current_time := i64(current_time) + time_info.tm_gmtoff

	return time.from_nanoseconds(local_current_time * 1e9)
}

debug_values :: proc(editor, path: cstring) {
	fmt.println("===== DEBUG VALUES =====")
	fmt.printfln("editor: '%s', filepath: '%s'", editor, path)
}
