#' Color scales defined by Auth0's design team
#'
#' @description
#' The `auth0` scales provides color palettes provided by Auth0's design team. They are meant to be used in combination with the auth0_theme in ggplot2
#'
#' @details
#' The `auth0` scales were carefully designed and tested on discrete data.
#'
#' @section Palettes:
#' The following palettes are available for use with these scales:
#' \describe{
#'   \item{default}{Default palette alternating between colors ranging from yellow to orange}
#'   \item{sequential}{Colors ordered from lighter to darker, meant for ordinal variables}
#'   \item{colorful}{Colorful alternative respecting Auth0's style}
#' }
#'
#' @param ... Other arguments passed on to [discrete_scale()] to control name,
#'   limits, breaks, labels and so forth.
#' @param palette The palette to use, if left empty will use the default one, you can also choose the sequential one if the value is ordinal, or colorful to use many different colors.
#' @param direction The direction to use, if -1 will return the colors in opposite order
#' @param aesthetics The aesthetic to apply this scale on
#' @param midpoint The mid value on gradients, should always set this to the mean or median of the value to colour.
#' @param space colour space in which to calculate gradient. Must be "Lab" - other values are deprecated.
#' @param na.value Colour to use for missing values
#' @param guide Type of legend. Use "colourbar" for continuous colour bar, or "legend" for discrete colour legend.
#' @rdname scale_auth0
#' @export
#' @examples
#'
#' ggplot(diamonds, aes(clarity, fill = cut)) +
#' geom_bar() +
#' theme_auth0() +
#' scale_fill_auth0_discrete(palette='colorful')
#'
#' ggplot(diamonds, aes(x= cut, y = depth, color = cut)) +
#' geom_violin(fill = '#fffffa') +
#' theme_auth0() +
#' scale_color_auth0_discrete()
#'
#' ggplot(diamonds, aes(x= depth, y = price, color = price)) +
#' geom_point() + theme_auth0() + scale_color_auth0_gradient(midpoint=10000)
#'
#' @importFrom ggplot2 discrete_scale
scale_color_auth0_discrete = function (..., palette = 'default', direction = 1, aesthetics = "colour")
{
    discrete_scale(aesthetics, "auth0", auth0_palette(direction, palette), ...)
}

#' @export
#' @rdname scale_auth0
scale_fill_auth0_discrete <- function(..., palette = 'default', direction = 1, aesthetics = "fill") {
    discrete_scale(aesthetics, "auth0", auth0_palette(direction, palette), ...)
}

#' @importFrom scales div_gradient_pal
#' @importFrom ggplot2 continuous_scale
#' @export
#' @rdname scale_auth0
scale_fill_auth0_gradient <- function (..., midpoint = 0, space = "Lab", na.value = "grey50", guide = "colourbar", aesthetics = "fill")
{
    continuous_scale(aesthetics, "gradient_auth0", div_gradient_pal('#FF9C42',
        '#EB5424', '#A61617', space), na.value = na.value, guide = guide,
        ..., rescaler = mid_rescaler(mid = midpoint))
}

#' @export
#' @rdname scale_auth0
scale_color_auth0_gradient <- function (..., midpoint = 0, space = "Lab", na.value = "grey50", guide = "colourbar", aesthetics = "colour")
{
    continuous_scale(aesthetics, "gradient_auth0", div_gradient_pal('#FF9C42',
        '#EB5424', '#A61617', space), na.value = na.value, guide = guide,
        ..., rescaler = mid_rescaler(mid = midpoint))
}

#' Theme defined by Auth0's design team
#'
#' @description
#' The `auth0` theme provides a carefully designed theme with help from Auth0's design team. They are meant to be used in combination the auth0 palettes
#'
#' @examples
#'
#' ggplot(diamonds, aes(clarity, fill = cut)) +
#' geom_bar() +
#' theme_auth0() +
#' scale_fill_auth0_discrete(palette='colorful')
#'
#' @export
#' @importFrom ggplot2 theme element_text element_line element_rect
theme_auth0 <- function(){
  theme(
    plot.title = element_text(family = "Fakt ProUI SemiBold", size = 18),
    plot.subtitle = element_text(family = "Fakt ProUI Normal", size = 16, colour = "gray40"),
    panel.grid.major = element_line(colour = "gray85"),
    panel.grid.minor = element_line(colour = "gray90"),
    axis.title = element_text(family = "Fakt ProUI Normal", size = 16),
    axis.text.x = element_text(family = "Roboto Mono", size = 9, colour='gray50', angle=45),
    axis.text.y = element_text(family = "Roboto Mono", size = 8, colour='gray50'),
    legend.text = element_text(family = "Fakt ProUI Normal"),
    legend.title = element_text(family = "Fakt ProUI SemiBold"),
    panel.background = element_rect(fill = NA),
    legend.background = element_rect(fill = NA),
    axis.ticks = element_line(colour='gray85')
    )
}



#' @importFrom scales rescale_mid
mid_rescaler <- function(mid) {
  function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
    rescale_mid(x, to, from, mid)
  }
}

auth0_palette = function(direction=1, palette='default'){
  force(direction) #Evaluate direction to have it available below

  function(num){
    palettes = list(
      'default' = c('#EC5B2A', '#A83826', '#FFBE82', '#F47F4A', '#C94320', '#6A1415', '#F9A168'),
      'sequential'=c('#FFAA5C','#F9924C', '#F27338', '#EB5424', '#D4411F', '#B52D1D', '#99181A'),
      'colorful'=c('#EC5B2A','#78ADEB','#FBC366','#5AB692','#FFA062','#496FB4','#EB9ED5')
    )

    x = palettes[[palette]]
    if(num<length(x)){
      x = x[1:num]
    }else if (num>length(x)){
      warning("More colors requested than available for this palette, the max is ", length(x),'. Will apply only those colors to the chart. Try reducing the number of categories in the chart, too many are usually difficult to read anyway.')
    }

    if(direction==-1){
      rev(x)
    }else{
      x
    }
  }

}




# British - American spellings ----------------------------------------------

#' @export
#' @rdname scale_auth0
#' @usage NULL
scale_colour_auth0_discrete <- scale_color_auth0_discrete

#' @export
#' @rdname scale_auth0
#' @usage NULL
scale_colour_auth0_gradient <- scale_color_auth0_gradient

