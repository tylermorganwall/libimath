#' Print the Imath library version info
#'
#' @return None.
#' @export
#' @examples
#' # Print the Imath version provided in the static library
#' print_imath_version()
print_imath_version = function() {
  .Call(
    "C_print_imath_version",
    PACKAGE = "libimath"
  )
  return(invisible())
}
