args = commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("usage: write-runtime-metadata.R <library-directory>")
}

lib_dir = normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
archive = file.path(lib_dir, "libImath-3_2.a")
metadata_file = file.path(lib_dir, "libimath-runtime-link-flags")

read_symbols = function(path) {
  if (!file.exists(path)) {
    return(character())
  }

  nm = Sys.which("nm")
  if (!nzchar(nm)) {
    return(character())
  }

  tryCatch(
    system2(nm, c("-g", path), stdout = TRUE, stderr = FALSE),
    error = function(e) character()
  )
}

append_unique = function(x, value) {
  unique(c(x, value))
}

symbols = read_symbols(archive)
has_symbol = function(pattern) {
  any(grepl(pattern, symbols, fixed = TRUE))
}

is_windows = identical(.Platform$OS.type, "windows")
is_macos = identical(Sys.info()[["sysname"]], "Darwin")

runtime_flags = character()
if (!is_windows && !is_macos && has_symbol("_ZNSt3__1")) {
  runtime_flags = append_unique(runtime_flags, "-lc++")
}
if (!is_windows && has_symbol("__ubsan_handle")) {
  runtime_flags = append_unique(runtime_flags, "-fsanitize=undefined")
}
if (!is_windows && has_symbol("__asan_")) {
  runtime_flags = append_unique(runtime_flags, "-fsanitize=address")
}
if (!is_windows && has_symbol("__tsan_")) {
  runtime_flags = append_unique(runtime_flags, "-fsanitize=thread")
}

runtime_flags_text = paste(runtime_flags, collapse = " ")
invisible(writeLines(runtime_flags_text, metadata_file, useBytes = TRUE))

remove_marked_block = function(lines, begin, end) {
  start = grep(begin, lines, fixed = TRUE)
  stop = grep(end, lines, fixed = TRUE)

  if (length(start) == 0 || length(stop) == 0) {
    return(lines)
  }

  keep = rep(TRUE, length(lines))
  for (idx in seq_along(start)) {
    matching_stop = stop[stop >= start[[idx]]][[1]]
    keep[start[[idx]]:matching_stop] = FALSE
  }
  lines[keep]
}

patch_pkg_config = function(path, flags) {
  if (!file.exists(path)) {
    return(invisible(FALSE))
  }

  lines = readLines(path, warn = FALSE)
  private_lines = grep("^Libs\\.private:", lines, value = TRUE)
  private_flags = trimws(sub("^Libs\\.private:\\s*", "", private_lines))
  private_flags = unlist(strsplit(paste(private_flags, collapse = " "), "\\s+"))
  private_flags = private_flags[nzchar(private_flags)]
  all_flags = unique(c(private_flags, flags))

  lines = lines[!grepl("^Libs\\.private:", lines)]

  if (length(all_flags) > 0) {
    libs_line = grep("^Libs:", lines)
    if (length(libs_line) > 0) {
      lines = append(
        lines,
        paste("Libs.private:", paste(all_flags, collapse = " ")),
        after = libs_line[[1]]
      )
    }
  }

  writeLines(lines, path, useBytes = TRUE)
  invisible(TRUE)
}

as_cmake_link_interface = function(flags) {
  libraries = character()
  options = character()

  for (flag in flags) {
    if (startsWith(flag, "-l")) {
      libraries = append_unique(libraries, sub("^-l", "", flag))
    } else {
      options = append_unique(options, flag)
    }
  }

  list(
    libraries = libraries,
    options = options
  )
}

patch_cmake_targets = function(path, flags) {
  if (!file.exists(path)) {
    return(invisible(FALSE))
  }

  begin = "# libimath R package runtime link flags begin"
  end = "# libimath R package runtime link flags end"
  lines = remove_marked_block(readLines(path, warn = FALSE), begin, end)

  if (length(flags) > 0) {
    cmake_interface = as_cmake_link_interface(flags)
    insert_before = grep(
      "^# Load information for each installed configuration\\.",
      lines
    )

    block = begin
    if (length(cmake_interface$libraries) > 0) {
      block = c(
        block,
        "set_property(TARGET Imath::Imath APPEND PROPERTY",
        sprintf(
          '  INTERFACE_LINK_LIBRARIES "%s"',
          paste(cmake_interface$libraries, collapse = ";")
        ),
        ")"
      )
    }
    if (length(cmake_interface$options) > 0) {
      block = c(
        block,
        "set_property(TARGET Imath::Imath APPEND PROPERTY",
        sprintf(
          '  INTERFACE_LINK_OPTIONS "%s"',
          paste(cmake_interface$options, collapse = ";")
        ),
        ")"
      )
    }
    block = c(block, end, "")

    if (length(insert_before) > 0) {
      lines = append(lines, block, after = insert_before[[1]] - 1)
    } else {
      lines = c(lines, "", block)
    }
  }

  writeLines(lines, path, useBytes = TRUE)
  invisible(TRUE)
}

patch_pkg_config(file.path(lib_dir, "pkgconfig", "Imath.pc"), runtime_flags)
patch_cmake_targets(
  file.path(lib_dir, "cmake", "Imath", "ImathTargets.cmake"),
  runtime_flags
)

invisible(
  if (nzchar(runtime_flags_text)) {
    message(sprintf(
      "Recorded libImath runtime link flags: %s",
      runtime_flags_text
    ))
  } else {
    message("No extra libImath runtime link flags detected")
  }
)
