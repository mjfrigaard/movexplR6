# Filter inputs module server

Returns a reactive list of all current filter and axis selections.

## Usage

``` r
mod_filters_server(id)
```

## Arguments

- id:

  Module namespace ID.

## Value

A reactive list with elements: `reviews`, `oscars`, `year`, `boxoffice`,
`genre`, `director`, `cast`, `xvar`, `yvar`.
