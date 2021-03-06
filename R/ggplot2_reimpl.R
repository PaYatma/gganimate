# copied from (and modified) ggplot2
plot_clone <- function(plot) {
  p <- plot
  p$scales <- plot$scales$clone()
  p$coordinates <- ggproto(NULL, plot$coordinates)
  p$transmuters <- plot$transmuters$clone()
  p
}
scales_transform_df <- function(scales, df) {
  if (empty(df) || length(scales$scales) == 0) return(df)

  transformed <- unlist(lapply(scales$scales, function(s) s$transform_df(df = df)),
                        recursive = FALSE)
  plyr::quickdf(c(transformed, df[setdiff(names(df), names(transformed))]))
}
empty <- function(df) {
  is.null(df) || nrow(df) == 0 || ncol(df) == 0
}
scales_add_missing <- function(plot, aesthetics, env) {

  # Keep only aesthetics that aren't already in plot$scales
  aesthetics <- setdiff(aesthetics, plot$scales$input())

  for (aes in aesthetics) {
    scale_name <- paste("scale", aes, "continuous", sep = "_")

    scale_f <- find_global(scale_name, env, mode = "function")
    plot$scales$add(scale_f())
  }
}
find_global <- function(name, env, mode = "any") {
  if (exists(name, envir = env, mode = mode)) {
    return(get(name, envir = env, mode = mode))
  }

  nsenv <- asNamespace("ggplot2")
  if (exists(name, envir = nsenv, mode = mode)) {
    return(get(name, envir = nsenv, mode = mode))
  }

  NULL
}
scales_train_df <- function(scales, df, drop = FALSE) {
  if (empty(df) || length(scales$scales) == 0) return()

  lapply(scales$scales, function(scale) scale$train_df(df = df))
}
scales_map_df <- function(scales, df) {
  if (empty(df) || length(scales$scales) == 0) return(df)

  mapped <- unlist(lapply(scales$scales, function(scale) scale$map_df(df = df)), recursive = FALSE)

  plyr::quickdf(c(mapped, df[setdiff(names(df), names(mapped))]))
}
is.waive <- function(x) inherits(x, 'waiver')

# Reimplement get_scales in Layout to allow panels with frame info to get the
# correct scales
#' @importFrom ggplot2 FacetNull CoordCartesian Layout ggproto
create_layout <- function(facet = FacetNull, coord = CoordCartesian) {
  ggproto(NULL, Layout,
    facet = facet,
    coord = coord,
    get_scales = function(self, i) {
      if (is.character(i)) i <- as.integer(strsplit(i, '<')[[1]][1])
      this_panel <- self$layout[self$layout$PANEL == i, ]

      list(
        x = self$panel_scales_x[[this_panel$SCALE_X]],
        y = self$panel_scales_y[[this_panel$SCALE_Y]]
      )
    }
  )
}
